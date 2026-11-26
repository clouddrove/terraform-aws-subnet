# Managed By : CloudDrove
# Copyright @ CloudDrove. All Right Reserved.

##-----------------------------------------------------------------------------
## Locals declration to determine count of public subnet, private subnet, and nat gateway.
##-----------------------------------------------------------------------------
locals {
  selected_availability_zones = length(var.availability_zone_ids) > 0 ? var.availability_zone_ids : var.availability_zones
  availability_zone_count     = length(local.selected_availability_zones)
  public_count                = var.enable && (var.type == "public" || var.type == "public-private") ? local.availability_zone_count : 0
  private_count               = var.enable && (var.type == "private" || var.type == "public-private") ? local.availability_zone_count : 0
  is_regional_nat_gateway     = var.nat_gateway_availability_mode == "regional"
  nat_gateway_count           = var.enable && var.nat_gateway_enabled && local.private_count > 0 && (local.is_regional_nat_gateway || !(var.type == "public-private" && var.public_subnet_ipv6_native)) ? (local.is_regional_nat_gateway || var.single_nat_gateway ? 1 : local.private_count) : 0
  # When a single NAT Gateway is actually created and shared via single_nat_gateway, only 1 route table is needed —
  # all private subnets associate with index 0. Creating one per AZ produces orphaned tables with no routes.
  private_rt_count = local.private_count > 0 && local.nat_gateway_count == 1 && var.single_nat_gateway ? 1 : local.private_count

  public_additional_routes_expanded = var.enable ? flatten([
    for az_index, az in local.selected_availability_zones : concat(
      [
        for route in var.additional_public_routes_for_all : merge(route, {
          az_index = tostring(az_index)
          az_name  = az
        })
      ],
      [
        for route in lookup(var.additional_public_routes_per_subnet, az, []) : merge(route, {
          az_index = tostring(az_index)
          az_name  = az
        })
      ]
    )
  ]) : []

  private_additional_routes_expanded = var.enable ? flatten([
    for az_index, az in local.selected_availability_zones : concat(
      [
        for route in(local.private_rt_count == 1 && az_index > 0 ? [] : var.additional_private_routes_for_all) : merge(route, {
          az_index = tostring(az_index)
          az_name  = az
        })
      ],
      [
        for route in lookup(var.additional_private_routes_per_subnet, az, []) : merge(route, {
          az_index = tostring(az_index)
          az_name  = az
        })
      ]
    )
  ]) : []
}
##-----------------------------------------------------------------------------
## Labels module called that will be used for naming and tags.
##-----------------------------------------------------------------------------
module "private-labels" {
  source  = "clouddrove/labels/aws"
  version = "1.3.1"

  name        = var.name
  repository  = var.repository
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  attributes  = compact(concat(var.attributes, ["private"]))
  extra_tags = merge(var.tags, {
    Type = "private"
  })
}

module "public-labels" {
  source  = "clouddrove/labels/aws"
  version = "1.3.1"

  name        = var.name
  repository  = var.repository
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  attributes  = compact(concat(var.attributes, ["public"]))
  extra_tags = merge(var.tags, {
    Type = "public"
  })
}

##-----------------------------------------------------------------------------
## Below resource will deploy public subnets and its related components in aws environment.
##-----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                                          = local.public_count
  region                                         = var.region
  vpc_id                                         = var.vpc_id
  availability_zone                              = length(var.availability_zone_ids) == 0 ? local.selected_availability_zones[count.index] : null
  availability_zone_id                           = length(var.availability_zone_ids) > 0 ? local.selected_availability_zones[count.index] : null
  cidr_block                                     = var.public_subnet_ipv6_native || var.ipv4_ipam_pool_id != null ? null : (length(var.ipv4_public_cidrs) == 0 ? cidrsubnet(var.cidr_block, ceil(log(local.public_count * 2, 2)), local.public_count + count.index) : var.ipv4_public_cidrs[count.index])
  ipv4_ipam_pool_id                              = var.public_subnet_ipv6_native ? null : var.ipv4_ipam_pool_id
  ipv4_netmask_length                            = var.public_subnet_ipv6_native ? null : var.ipv4_netmask_length
  ipv6_cidr_block                                = var.enable_ipv6 && var.ipv6_ipam_pool_id == null ? (length(var.public_ipv6_cidrs) == 0 ? cidrsubnet(var.ipv6_cidr_block, 8, count.index + 1) : var.public_ipv6_cidrs[count.index]) : null
  ipv6_ipam_pool_id                              = var.enable_ipv6 ? var.ipv6_ipam_pool_id : null
  ipv6_netmask_length                            = var.enable_ipv6 ? var.ipv6_netmask_length : null
  map_public_ip_on_launch                        = var.public_subnet_ipv6_native ? false : var.map_public_ip_on_launch
  assign_ipv6_address_on_creation                = var.enable_ipv6 && (var.public_subnet_ipv6_native || var.public_subnet_assign_ipv6_address_on_creation)
  private_dns_hostname_type_on_launch            = var.public_subnet_private_dns_hostname_type_on_launch
  ipv6_native                                    = var.public_subnet_ipv6_native
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.public_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.public_subnet_ipv6_native && var.public_subnet_enable_resource_name_dns_a_record_on_launch
  enable_dns64                                   = var.enable_ipv6 && var.public_subnet_enable_dns64
  outpost_arn                                    = var.public_subnet_outpost_arn
  customer_owned_ipv4_pool                       = var.public_subnet_ipv6_native ? null : var.public_subnet_customer_owned_ipv4_pool
  map_customer_owned_ip_on_launch                = var.public_subnet_outpost_arn != null && var.public_subnet_customer_owned_ipv4_pool != null ? (var.public_subnet_ipv6_native ? false : var.public_subnet_map_customer_owned_ip_on_launch) : null
  enable_lni_at_device_index                     = var.public_subnet_enable_lni_at_device_index
  tags = merge(
    module.public-labels.tags,
    var.extra_public_tags,
    lookup(var.public_subnet_tags_per_az, local.selected_availability_zones[count.index], {}),
    {
      "Name" = format("%s%s%s", module.public-labels.id, var.delimiter, local.selected_availability_zones[count.index])
      "AZ"   = local.selected_availability_zones[count.index]
    }
  )
  lifecycle {
    # Ignore tags added by kubernetes
    ignore_changes = [
      tags["kubernetes.io"],
      tags["SubnetType"],
    ]
  }
}

##-----------------------------------------------------------------------------
## Below resource will deploy network acl and its rules that will be attached to public subnets.
##-----------------------------------------------------------------------------
resource "aws_network_acl" "public" {
  count      = var.enable && local.public_count > 0 && var.enable_public_acl && (var.type == "public" || var.type == "public-private") ? 1 : 0
  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.public[*].id
  tags       = merge(module.public-labels.tags, var.public_acl_tags)
  depends_on = [aws_subnet.public]
}

resource "aws_network_acl_rule" "public_inbound" {
  count           = var.enable && local.public_count > 0 && var.enable_public_acl && (var.type == "public" || var.type == "public-private") ? length(var.public_inbound_acl_rules) : 0
  region          = var.region
  network_acl_id  = aws_network_acl.public[0].id
  egress          = false
  rule_number     = var.public_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "public_outbound" {
  count           = var.enable && local.public_count > 0 && var.enable_public_acl && (var.type == "public" || var.type == "public-private") ? length(var.public_outbound_acl_rules) : 0
  region          = var.region
  network_acl_id  = aws_network_acl.public[0].id
  egress          = true
  rule_number     = var.public_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

##-----------------------------------------------------------------------------
## Below resources will deploy route table and routes for public subnet and will be associated to public subnets.
##-----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  count            = local.public_count
  region           = var.region
  vpc_id           = var.vpc_id
  propagating_vgws = length(var.public_propagating_vgws) > 0 ? var.public_propagating_vgws : null
  tags = merge(
    module.public-labels.tags,
    var.public_route_table_tags,
    {
      "Name" = format("%s%s%s-rt", module.public-labels.id, var.delimiter, local.selected_availability_zones[count.index])
      "AZ"   = local.selected_availability_zones[count.index]
    }
  )
}

resource "aws_route" "public" {
  count                  = var.public_subnet_ipv6_native ? 0 : local.public_count
  region                 = var.region
  route_table_id         = element(aws_route_table.public[*].id, count.index)
  gateway_id             = var.igw_id
  destination_cidr_block = var.public_rt_ipv4_destination_cidr
  depends_on             = [aws_route_table.public]
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_ipv6" {
  count                       = var.enable_ipv6 ? local.public_count : 0
  region                      = var.region
  route_table_id              = element(aws_route_table.public[*].id, count.index)
  gateway_id                  = var.igw_id
  destination_ipv6_cidr_block = var.public_rt_ipv6_destination_cidr
  depends_on                  = [aws_route_table.public]
}

resource "aws_route_table_association" "public" {
  count          = local.public_count
  region         = var.region
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = element(aws_route_table.public[*].id, count.index)
  depends_on = [
    aws_subnet.public,
    aws_route_table.public,
  ]
}

##-----------------------------------------------------------------------------
## Below resource will deploy flow logs for public subnet.
##-----------------------------------------------------------------------------
resource "aws_flow_log" "public_subnet_flow_log" {
  count                      = var.enable && var.enable_flow_log ? local.public_count : 0
  region                     = var.region
  log_destination_type       = var.flow_log_destination_type
  log_destination            = var.flow_log_destination_arn
  log_format                 = var.flow_log_log_format
  iam_role_arn               = var.flow_log_iam_role_arn
  deliver_cross_account_role = var.flow_log_deliver_cross_account_role
  traffic_type               = var.flow_log_traffic_type
  subnet_id                  = aws_subnet.public[count.index].id
  max_aggregation_interval   = var.flow_log_max_aggregation_interval
  dynamic "destination_options" {
    for_each = var.flow_log_destination_type == "s3" ? [true] : []
    content {
      file_format                = var.flow_log_file_format
      hive_compatible_partitions = var.flow_log_hive_compatible_partitions
      per_hour_partition         = var.flow_log_per_hour_partition
    }
  }
  tags = merge(
    module.public-labels.tags,
    var.flow_log_tags,
    { "Name" = format("%s-%s-flowlog", module.public-labels.name, local.selected_availability_zones[count.index]) }
  )
}

##-----------------------------------------------------------------------------
## Below resource will deploy private subnets and its related components in aws environment.
##-----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count                                          = local.private_count
  region                                         = var.region
  vpc_id                                         = var.vpc_id
  availability_zone                              = length(var.availability_zone_ids) == 0 ? local.selected_availability_zones[count.index] : null
  availability_zone_id                           = length(var.availability_zone_ids) > 0 ? local.selected_availability_zones[count.index] : null
  cidr_block                                     = var.private_subnet_ipv6_native || var.ipv4_ipam_pool_id != null ? null : (length(var.ipv4_private_cidrs) == 0 ? cidrsubnet(var.cidr_block, local.public_count == 0 ? ceil(log(local.private_count * 2, 2)) : ceil(log(local.public_count * 2, 2)), count.index) : var.ipv4_private_cidrs[count.index])
  ipv4_ipam_pool_id                              = var.private_subnet_ipv6_native ? null : var.ipv4_ipam_pool_id
  ipv4_netmask_length                            = var.private_subnet_ipv6_native ? null : var.ipv4_netmask_length
  ipv6_cidr_block                                = var.enable_ipv6 && var.ipv6_ipam_pool_id == null ? (length(var.private_ipv6_cidrs) == 0 ? cidrsubnet(var.ipv6_cidr_block, 8, local.public_count + count.index + 1) : var.private_ipv6_cidrs[count.index]) : null
  ipv6_ipam_pool_id                              = var.enable_ipv6 ? var.ipv6_ipam_pool_id : null
  ipv6_netmask_length                            = var.enable_ipv6 ? var.ipv6_netmask_length : null
  assign_ipv6_address_on_creation                = var.enable_ipv6 && (var.private_subnet_ipv6_native || var.private_subnet_assign_ipv6_address_on_creation)
  private_dns_hostname_type_on_launch            = var.private_subnet_private_dns_hostname_type_on_launch
  ipv6_native                                    = var.private_subnet_ipv6_native
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.private_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.private_subnet_ipv6_native && var.private_subnet_enable_resource_name_dns_a_record_on_launch
  enable_dns64                                   = var.enable_ipv6 && var.private_subnet_enable_dns64
  outpost_arn                                    = var.private_subnet_outpost_arn
  customer_owned_ipv4_pool                       = var.private_subnet_ipv6_native ? null : var.private_subnet_customer_owned_ipv4_pool
  map_customer_owned_ip_on_launch                = var.private_subnet_outpost_arn != null && var.private_subnet_customer_owned_ipv4_pool != null ? (var.private_subnet_ipv6_native ? false : var.private_subnet_map_customer_owned_ip_on_launch) : null
  enable_lni_at_device_index                     = var.private_subnet_enable_lni_at_device_index

  tags = merge(
    module.private-labels.tags,
    var.extra_private_tags,
    lookup(var.private_subnet_tags_per_az, local.selected_availability_zones[count.index], {}),
    {
      "Name" = format("%s%s%s", module.private-labels.id, var.delimiter, local.selected_availability_zones[count.index])
      "AZ"   = local.selected_availability_zones[count.index]
    }
  )

  lifecycle {
    # Ignore tags added by kubernetes
    ignore_changes = [
      tags["kubernetes.io"],
      tags["SubnetType"],
    ]
  }
}

##-----------------------------------------------------------------------------
## Below resource will deploy network acl and its rules that will be attached to private subnets.
##-----------------------------------------------------------------------------
resource "aws_network_acl" "private" {
  count      = var.enable && local.private_count > 0 && var.enable_private_acl && (var.type == "private" || var.type == "public-private") ? 1 : 0
  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.private[*].id
  tags       = merge(module.private-labels.tags, var.private_acl_tags)
  depends_on = [aws_subnet.private]
}

resource "aws_network_acl_rule" "private_inbound" {
  count           = var.enable && local.private_count > 0 && var.enable_private_acl && (var.type == "private" || var.type == "public-private") ? length(var.private_inbound_acl_rules) : 0
  region          = var.region
  network_acl_id  = aws_network_acl.private[0].id
  egress          = false
  rule_number     = var.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count           = var.enable && local.private_count > 0 && var.enable_private_acl && (var.type == "private" || var.type == "public-private") ? length(var.private_outbound_acl_rules) : 0
  region          = var.region
  network_acl_id  = aws_network_acl.private[0].id
  egress          = true
  rule_number     = var.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

##-----------------------------------------------------------------------------
## Below resources will deploy route table and routes for private subnet and will be associated to private subnets.
##-----------------------------------------------------------------------------
resource "aws_route_table" "private" {
  count            = local.private_rt_count
  region           = var.region
  vpc_id           = var.vpc_id
  propagating_vgws = length(var.private_propagating_vgws) > 0 ? var.private_propagating_vgws : null
  tags = merge(
    module.private-labels.tags,
    var.private_route_table_tags,
    {
      "Name" = format("%s%s%s-rt", module.private-labels.id, var.delimiter, local.selected_availability_zones[count.index])
      "AZ"   = local.selected_availability_zones[count.index]
    }
  )
}

resource "aws_route_table_association" "private" {
  count          = local.private_count
  region         = var.region
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, local.private_rt_count == 1 ? 0 : count.index)
}

resource "aws_route" "nat_gateway" {
  count                  = local.nat_gateway_count > 0 && !var.private_subnet_ipv6_native ? local.private_rt_count : 0
  region                 = var.region
  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.private[*].id, local.nat_gateway_count == 1 ? 0 : count.index)
  depends_on             = [aws_route_table.private]
}

resource "aws_route" "nat64" {
  count                       = local.nat_gateway_count > 0 && var.enable_ipv6 && var.enable_nat64 ? local.private_rt_count : 0
  region                      = var.region
  route_table_id              = element(aws_route_table.private[*].id, count.index)
  destination_ipv6_cidr_block = var.nat64_destination_ipv6_cidr_block
  nat_gateway_id              = element(aws_nat_gateway.private[*].id, local.nat_gateway_count == 1 ? 0 : count.index)
  depends_on                  = [aws_route_table.private]
}

resource "aws_route" "private_ipv6" {
  count                       = var.enable_ipv6 && var.enable_eigw ? local.private_rt_count : 0
  region                      = var.region
  route_table_id              = element(aws_route_table.private[*].id, count.index)
  egress_only_gateway_id      = var.eigw_id
  destination_ipv6_cidr_block = var.private_rt_ipv6_destination_cidr
  depends_on                  = [aws_route_table.private]
}

##----------------------------------------------------------------------------------
## Below resource will create Elastic IP (EIP) for nat gateway.
##----------------------------------------------------------------------------------
resource "aws_eip" "private" {
  # Only zonal public NAT gateways need module-managed EIPs when not reusing external EIPs
  count  = !local.is_regional_nat_gateway && var.nat_gateway_connectivity_type == "public" && !var.reuse_nat_ips ? local.nat_gateway_count : 0
  region = var.region
  domain = "vpc"
  tags = merge(
    module.private-labels.tags,
    var.nat_eip_tags,
    {
      "Name" = format("%s%s%s-eip", module.private-labels.id, var.delimiter, local.selected_availability_zones[var.single_nat_gateway ? 0 : count.index])
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}

##----------------------------------------------------------------------------------
## Below resource will deploy nat gateway for private subnets.
##----------------------------------------------------------------------------------
resource "aws_nat_gateway" "private" {
  count                              = local.nat_gateway_count
  region                             = var.region
  vpc_id                             = local.is_regional_nat_gateway ? var.vpc_id : null
  availability_mode                  = local.is_regional_nat_gateway ? "regional" : null
  connectivity_type                  = var.nat_gateway_connectivity_type
  allocation_id                      = !local.is_regional_nat_gateway && var.nat_gateway_connectivity_type == "public" ? (var.reuse_nat_ips ? element(var.external_nat_ip_ids, count.index) : element(aws_eip.private[*].id, count.index)) : null
  subnet_id                          = local.is_regional_nat_gateway ? null : (length(aws_subnet.public) > 0 ? element(aws_subnet.public[*].id, var.single_nat_gateway ? 0 : count.index) : element(var.public_subnet_ids, var.single_nat_gateway ? 0 : count.index))
  secondary_private_ip_address_count = !local.is_regional_nat_gateway && var.nat_gateway_secondary_private_ip_address_count != null ? var.nat_gateway_secondary_private_ip_address_count : null

  dynamic "availability_zone_address" {
    for_each = local.is_regional_nat_gateway ? var.regional_nat_gateway_address : []
    content {
      allocation_ids       = availability_zone_address.value.allocation_ids
      availability_zone    = availability_zone_address.value.availability_zone
      availability_zone_id = availability_zone_address.value.availability_zone_id
    }
  }

  tags = merge(
    module.private-labels.tags,
    var.nat_gateway_tags,
    {
      "Name" = local.is_regional_nat_gateway ? format("%s%sregional-nat-gateway", module.private-labels.id, var.delimiter) : format("%s%s%s-nat-gateway", module.private-labels.id, var.delimiter, local.selected_availability_zones[var.single_nat_gateway ? 0 : count.index])
    }
  )
  # Ensures the IGW route (and therefore IGW itself) exists before NAT gateways are created
  depends_on = [aws_route.public]
}

##-----------------------------------------------------------------------------
## Below resource will deploy flow logs for private subnet.
##-----------------------------------------------------------------------------
resource "aws_flow_log" "private_subnet_flow_log" {
  count                      = var.enable && var.enable_flow_log ? local.private_count : 0
  region                     = var.region
  log_destination_type       = var.flow_log_destination_type
  log_destination            = var.flow_log_destination_arn
  log_format                 = var.flow_log_log_format
  iam_role_arn               = var.flow_log_iam_role_arn
  deliver_cross_account_role = var.flow_log_deliver_cross_account_role
  traffic_type               = var.flow_log_traffic_type
  subnet_id                  = aws_subnet.private[count.index].id
  max_aggregation_interval   = var.flow_log_max_aggregation_interval
  dynamic "destination_options" {
    for_each = var.flow_log_destination_type == "s3" ? [true] : []
    content {
      file_format                = var.flow_log_file_format
      hive_compatible_partitions = var.flow_log_hive_compatible_partitions
      per_hour_partition         = var.flow_log_per_hour_partition
    }
  }
  tags = merge(
    module.private-labels.tags,
    var.flow_log_tags,
    { "Name" = format("%s-%s-flowlog", module.private-labels.name, local.selected_availability_zones[count.index]) }
  )
}

##-----------------------------------------------------------------------------
## Below resources will deploy additional routes for public route tables.
## Controlled by var.enable — when false, no routes are created.
## Routes are only created when caller explicitly passes values.
##-----------------------------------------------------------------------------
resource "aws_route" "public_additional" {
  for_each = var.enable ? {
    for r in local.public_additional_routes_expanded :
    "${r.az_name}|${coalesce(lookup(r, "destination_cidr_block", null), lookup(r, "destination_ipv6_cidr_block", null), lookup(r, "destination_prefix_list_id", null), "")}" => r
  } : {}
  region                      = var.region
  route_table_id              = aws_route_table.public[tonumber(each.value.az_index)].id
  destination_cidr_block      = lookup(each.value, "destination_cidr_block", null)
  destination_ipv6_cidr_block = lookup(each.value, "destination_ipv6_cidr_block", null)
  destination_prefix_list_id  = lookup(each.value, "destination_prefix_list_id", null)

  gateway_id                = lookup(each.value, "gateway_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)
  vpc_endpoint_id           = lookup(each.value, "vpc_endpoint_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
  egress_only_gateway_id    = lookup(each.value, "egress_only_gateway_id", null)
  carrier_gateway_id        = lookup(each.value, "carrier_gateway_id", null)
  local_gateway_id          = lookup(each.value, "local_gateway_id", null)
  core_network_arn          = lookup(each.value, "core_network_arn", null)

  depends_on = [aws_route_table.public]

  timeouts {
    create = "5m"
  }
}

##-----------------------------------------------------------------------------
## Below resources will deploy additional routes for private route tables.
## Controlled by var.enable — when false, no routes are created.
## Routes are only created when caller explicitly passes values.
##-----------------------------------------------------------------------------
resource "aws_route" "private_additional" {
  for_each = var.enable ? {
    for r in local.private_additional_routes_expanded :
    "${r.az_name}|${coalesce(lookup(r, "destination_cidr_block", null), lookup(r, "destination_ipv6_cidr_block", null), lookup(r, "destination_prefix_list_id", null), "")}" => r
  } : {}

  region                      = var.region
  route_table_id              = local.private_rt_count == 1 ? aws_route_table.private[0].id : aws_route_table.private[tonumber(each.value.az_index)].id
  destination_cidr_block      = lookup(each.value, "destination_cidr_block", null)
  destination_ipv6_cidr_block = lookup(each.value, "destination_ipv6_cidr_block", null)
  destination_prefix_list_id  = lookup(each.value, "destination_prefix_list_id", null)

  gateway_id                = lookup(each.value, "gateway_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)
  vpc_endpoint_id           = lookup(each.value, "vpc_endpoint_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
  egress_only_gateway_id    = lookup(each.value, "egress_only_gateway_id", null)
  carrier_gateway_id        = lookup(each.value, "carrier_gateway_id", null)
  local_gateway_id          = lookup(each.value, "local_gateway_id", null)
  core_network_arn          = lookup(each.value, "core_network_arn", null)

  depends_on = [aws_route_table.private]

  timeouts {
    create = "5m"
  }
}
