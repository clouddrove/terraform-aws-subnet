# Managed By : CloudDrove
# Copyright @ CloudDrove. All Right Reserved.

##-----------------------------------------------------------------------------
## Locals declration to determine count of public subnet, private subnet, and nat gateway.
##-----------------------------------------------------------------------------
locals {
  create_public  = var.enable && contains(["public", "public-private"], var.type)
  create_private = var.enable && contains(["private", "public-private"], var.type)

  public_count  = local.create_public ? length(var.availability_zones) : 0
  private_count = local.create_private ? length(var.availability_zones) : 0

  # NAT gateways only make sense when there are private subnets to route through them.
  nat_gateway_count = local.private_count == 0 || !var.nat_gateway_enabled ? 0 : (var.single_nat_gateway ? 1 : length(var.availability_zones))

  # When single_nat_gateway=true, only 1 route table is needed — all private subnets
  # associate with index 0. Creating one per AZ produces orphaned tables with no routes.
  private_rt_count = local.private_count > 0 && var.single_nat_gateway ? 1 : local.private_count

  # Common tags (var.tags) are merged under the label tags so label values always win.
  public_tags  = merge(var.tags, module.public-labels.tags)
  private_tags = merge(var.tags, module.private-labels.tags)

  public_additional_routes_expanded = local.create_public ? flatten([
    for az_index, az in var.availability_zones : concat(
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

  private_additional_routes_expanded = local.create_private ? flatten([
    for az_index, az in var.availability_zones : concat(
      [
        for route in var.additional_private_routes_for_all : merge(route, {
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
  extra_tags = {
    Type = "private"
  }
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
  extra_tags = {
    Type = "public"
  }
}

##-----------------------------------------------------------------------------
## Below resource will deploy public subnets and its related components in aws environment.
##-----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                                          = local.public_count
  vpc_id                                         = var.vpc_id
  availability_zone                              = element(var.availability_zones, count.index)
  cidr_block                                     = var.public_subnet_ipv6_native ? null : (length(var.ipv4_public_cidrs) == 0 ? cidrsubnet(var.cidr_block, ceil(log(local.public_count * 2, 2)), local.public_count + count.index) : var.ipv4_public_cidrs[count.index])
  ipv6_cidr_block                                = var.enable_ipv6 ? (length(var.public_ipv6_cidrs) == 0 ? cidrsubnet(var.ipv6_cidr_block, 64 - tonumber(split("/", var.ipv6_cidr_block)[1]), count.index + 1) : var.public_ipv6_cidrs[count.index]) : null
  map_public_ip_on_launch                        = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.public_subnet_ipv6_native ? true : var.public_subnet_assign_ipv6_address_on_creation
  private_dns_hostname_type_on_launch            = var.public_subnet_private_dns_hostname_type_on_launch
  ipv6_native                                    = var.enable_ipv6 && var.public_subnet_ipv6_native
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.public_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.public_subnet_ipv6_native && var.public_subnet_enable_resource_name_dns_a_record_on_launch
  enable_dns64                                   = var.enable_ipv6 && var.public_subnet_enable_dns64
  tags = merge(
    var.tags, var.extra_public_tags, module.public-labels.tags,
    {
      "Name" = format("%s%s%s", module.public-labels.id, var.delimiter, element(var.availability_zones, count.index))
      "AZ"   = element(var.availability_zones, count.index)
    }
  )
  lifecycle {
    # Ignore tags added by kubernetes
    ignore_changes = [
      tags["kubernetes.io"],
      tags["SubnetType"],
    ]

    precondition {
      condition     = var.igw_id != ""
      error_message = "igw_id is required when type is `public` or `public-private` (the public route tables need an Internet Gateway)."
    }
    precondition {
      condition     = var.public_subnet_ipv6_native || length(var.ipv4_public_cidrs) > 0 || var.cidr_block != null
      error_message = "Set either cidr_block (subnets are derived from it) or ipv4_public_cidrs unless creating IPv6-native subnets."
    }
    precondition {
      condition     = length(var.ipv4_public_cidrs) == 0 || length(var.ipv4_public_cidrs) == length(var.availability_zones)
      error_message = "ipv4_public_cidrs must contain exactly one CIDR per availability zone."
    }
    precondition {
      condition     = !var.enable_ipv6 || var.ipv6_cidr_block != null || length(var.public_ipv6_cidrs) == length(var.availability_zones)
      error_message = "Set ipv6_cidr_block or provide one public_ipv6_cidrs entry per AZ when enable_ipv6 = true."
    }
    precondition {
      condition     = !var.enable_ipv6 || length(var.public_ipv6_cidrs) == 0 || length(var.public_ipv6_cidrs) == length(var.availability_zones)
      error_message = "public_ipv6_cidrs must contain exactly one CIDR per availability zone."
    }
    precondition {
      condition     = !var.enable_ipv6 || length(var.public_ipv6_cidrs) > 0 || try(pow(2, 64 - tonumber(split("/", var.ipv6_cidr_block)[1])) > local.public_count + local.private_count, false)
      error_message = "ipv6_cidr_block does not contain enough /64 ranges for the requested subnets; provide explicit public_ipv6_cidrs instead."
    }
    precondition {
      condition     = !var.public_subnet_ipv6_native || (var.enable_ipv6 && length(var.ipv4_public_cidrs) == 0)
      error_message = "IPv6-native public subnets require enable_ipv6 = true and cannot use ipv4_public_cidrs."
    }
  }
}

##-----------------------------------------------------------------------------
## Below resource will deploy network acl and its rules that will be attached to public subnets.
##-----------------------------------------------------------------------------
resource "aws_network_acl" "public" {
  count      = local.public_count > 0 && var.enable_public_acl ? 1 : 0
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.public[*].id
  tags       = local.public_tags
}

resource "aws_network_acl_rule" "public_inbound" {
  count           = local.public_count > 0 && var.enable_public_acl ? length(var.public_inbound_acl_rules) : 0
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
  count           = local.public_count > 0 && var.enable_public_acl ? length(var.public_outbound_acl_rules) : 0
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
  count  = local.public_count
  vpc_id = var.vpc_id
  tags = merge(
    local.public_tags,
    {
      "Name" = format("%s%s%s-rt", module.public-labels.id, var.delimiter, element(var.availability_zones, count.index))
      "AZ"   = element(var.availability_zones, count.index)
    }
  )
}

resource "aws_route" "public" {
  count                  = local.public_count
  route_table_id         = element(aws_route_table.public[*].id, count.index)
  gateway_id             = var.igw_id
  destination_cidr_block = var.public_rt_ipv4_destination_cidr
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_ipv6" {
  count                       = var.enable_ipv6 ? local.public_count : 0
  route_table_id              = element(aws_route_table.public[*].id, count.index)
  gateway_id                  = var.igw_id
  destination_ipv6_cidr_block = var.public_rt_ipv6_destination_cidr
}

resource "aws_route_table_association" "public" {
  count          = local.public_count
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = element(aws_route_table.public[*].id, count.index)
}

##-----------------------------------------------------------------------------
## Below resource will deploy flow logs for public subnet.
##-----------------------------------------------------------------------------
resource "aws_flow_log" "public_subnet_flow_log" {
  count                    = var.enable_flow_log ? local.public_count : 0
  log_destination_type     = var.flow_log_destination_type
  log_destination          = var.flow_log_destination_arn
  log_format               = var.flow_log_log_format
  iam_role_arn             = var.flow_log_iam_role_arn
  traffic_type             = var.flow_log_traffic_type
  subnet_id                = aws_subnet.public[count.index].id
  max_aggregation_interval = var.flow_log_max_aggregation_interval
  dynamic "destination_options" {
    for_each = var.flow_log_destination_type == "s3" ? [true] : []
    content {
      file_format                = var.flow_log_file_format
      hive_compatible_partitions = var.flow_log_hive_compatible_partitions
      per_hour_partition         = var.flow_log_per_hour_partition
    }
  }
  tags = merge(
    local.public_tags,
    { "Name" = format("%s-%s-flowlog", module.public-labels.name, element(var.availability_zones, count.index)) }
  )

  lifecycle {
    precondition {
      condition     = var.flow_log_destination_arn != null
      error_message = "flow_log_destination_arn is required when enable_flow_log = true."
    }
    precondition {
      condition     = var.flow_log_destination_type != "cloud-watch-logs" || var.flow_log_iam_role_arn != null
      error_message = "flow_log_iam_role_arn is required when flow_log_destination_type is `cloud-watch-logs`."
    }
  }
}

##-----------------------------------------------------------------------------
## Below resource will deploy private subnets and its related components in aws environment.
##-----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count                                          = local.private_count
  vpc_id                                         = var.vpc_id
  availability_zone                              = element(var.availability_zones, count.index)
  cidr_block                                     = var.private_subnet_ipv6_native ? null : (length(var.ipv4_private_cidrs) == 0 ? cidrsubnet(var.cidr_block, local.public_count == 0 ? ceil(log(local.private_count * 2, 2)) : ceil(log(local.public_count * 2, 2)), count.index) : var.ipv4_private_cidrs[count.index])
  ipv6_cidr_block                                = var.enable_ipv6 ? (length(var.private_ipv6_cidrs) == 0 ? cidrsubnet(var.ipv6_cidr_block, 64 - tonumber(split("/", var.ipv6_cidr_block)[1]), local.public_count + count.index + 1) : var.private_ipv6_cidrs[count.index]) : null
  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.private_subnet_ipv6_native ? true : var.private_subnet_assign_ipv6_address_on_creation
  private_dns_hostname_type_on_launch            = var.private_subnet_private_dns_hostname_type_on_launch
  ipv6_native                                    = var.enable_ipv6 && var.private_subnet_ipv6_native
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.private_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.private_subnet_ipv6_native && var.private_subnet_enable_resource_name_dns_a_record_on_launch
  enable_dns64                                   = var.enable_ipv6 && var.private_subnet_enable_dns64

  tags = merge(
    var.tags, var.extra_private_tags, module.private-labels.tags,
    {
      "Name" = format("%s%s%s", module.private-labels.id, var.delimiter, element(var.availability_zones, count.index))
      "AZ"   = element(var.availability_zones, count.index)
    }
  )

  lifecycle {
    # Ignore tags added by kubernetes
    ignore_changes = [
      tags["kubernetes.io"],
      tags["SubnetType"],
    ]

    precondition {
      condition     = var.private_subnet_ipv6_native || length(var.ipv4_private_cidrs) > 0 || var.cidr_block != null
      error_message = "Set either cidr_block (subnets are derived from it) or ipv4_private_cidrs unless creating IPv6-native subnets."
    }
    precondition {
      condition     = length(var.ipv4_private_cidrs) == 0 || length(var.ipv4_private_cidrs) == length(var.availability_zones)
      error_message = "ipv4_private_cidrs must contain exactly one CIDR per availability zone."
    }
    precondition {
      condition     = !var.enable_ipv6 || var.ipv6_cidr_block != null || length(var.private_ipv6_cidrs) == length(var.availability_zones)
      error_message = "Set ipv6_cidr_block or provide one private_ipv6_cidrs entry per AZ when enable_ipv6 = true."
    }
    precondition {
      condition     = !var.enable_ipv6 || length(var.private_ipv6_cidrs) == 0 || length(var.private_ipv6_cidrs) == length(var.availability_zones)
      error_message = "private_ipv6_cidrs must contain exactly one CIDR per availability zone."
    }
    precondition {
      condition     = !var.enable_ipv6 || length(var.private_ipv6_cidrs) > 0 || try(pow(2, 64 - tonumber(split("/", var.ipv6_cidr_block)[1])) > local.public_count + local.private_count, false)
      error_message = "ipv6_cidr_block does not contain enough /64 ranges for the requested subnets; provide explicit private_ipv6_cidrs instead."
    }
    precondition {
      condition     = !var.private_subnet_ipv6_native || (var.enable_ipv6 && length(var.ipv4_private_cidrs) == 0)
      error_message = "IPv6-native private subnets require enable_ipv6 = true and cannot use ipv4_private_cidrs."
    }
  }
}

##-----------------------------------------------------------------------------
## Below resource will deploy network acl and its rules that will be attached to private subnets.
##-----------------------------------------------------------------------------
resource "aws_network_acl" "private" {
  count      = local.private_count > 0 && var.enable_private_acl ? 1 : 0
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.private[*].id
  tags       = local.private_tags
}

resource "aws_network_acl_rule" "private_inbound" {
  count           = local.private_count > 0 && var.enable_private_acl ? length(var.private_inbound_acl_rules) : 0
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
  count           = local.private_count > 0 && var.enable_private_acl ? length(var.private_outbound_acl_rules) : 0
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
  count  = local.private_rt_count
  vpc_id = var.vpc_id
  tags = merge(
    local.private_tags,
    {
      "Name" = format("%s%s%s-rt", module.private-labels.id, var.delimiter, element(var.availability_zones, count.index))
      "AZ"   = element(var.availability_zones, count.index)
    }
  )
}

resource "aws_route_table_association" "private" {
  count          = local.private_count
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, var.single_nat_gateway ? 0 : count.index)
}

resource "aws_route" "nat_gateway" {
  count                  = local.nat_gateway_count
  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.private[*].id, count.index)
}

##----------------------------------------------------------------------------------
## Below resource will create Elastic IP (EIP) for nat gateway.
##----------------------------------------------------------------------------------
resource "aws_eip" "private" {
  # Only public NAT gateways need an EIP
  count  = var.nat_gateway_connectivity_type == "public" ? local.nat_gateway_count : 0
  domain = "vpc"
  tags = merge(
    local.private_tags,
    {
      "Name" = format("%s%s%s-eip", module.private-labels.id, var.delimiter, element(var.availability_zones, count.index))
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
  count             = local.nat_gateway_count
  connectivity_type = var.nat_gateway_connectivity_type
  allocation_id     = var.nat_gateway_connectivity_type == "public" ? element(aws_eip.private[*].id, count.index) : null
  subnet_id         = length(aws_subnet.public) > 0 ? element(aws_subnet.public[*].id, count.index) : element(var.public_subnet_ids, count.index)
  tags = merge(
    local.private_tags,
    {
      "Name" = format("%s%s%s-nat-gateway", module.private-labels.id, var.delimiter, element(var.availability_zones, count.index))
    }
  )
  # Ensures the IGW route (and therefore IGW itself) exists before NAT gateways are created
  depends_on = [aws_route.public]

  lifecycle {
    precondition {
      condition     = length(aws_subnet.public) > 0 ? length(aws_subnet.public) >= local.nat_gateway_count : length(var.public_subnet_ids) >= local.nat_gateway_count
      error_message = "Provide at least one public subnet per NAT gateway (or one when single_nat_gateway = true)."
    }
  }
}

##-----------------------------------------------------------------------------
## Below resource will deploy flow logs for private subnet.
##-----------------------------------------------------------------------------
resource "aws_flow_log" "private_subnet_flow_log" {
  count                    = var.enable_flow_log ? local.private_count : 0
  log_destination_type     = var.flow_log_destination_type
  log_destination          = var.flow_log_destination_arn
  log_format               = var.flow_log_log_format
  iam_role_arn             = var.flow_log_iam_role_arn
  traffic_type             = var.flow_log_traffic_type
  subnet_id                = aws_subnet.private[count.index].id
  max_aggregation_interval = var.flow_log_max_aggregation_interval
  dynamic "destination_options" {
    for_each = var.flow_log_destination_type == "s3" ? [true] : []
    content {
      file_format                = var.flow_log_file_format
      hive_compatible_partitions = var.flow_log_hive_compatible_partitions
      per_hour_partition         = var.flow_log_per_hour_partition
    }
  }
  tags = merge(
    local.private_tags,
    { "Name" = format("%s-%s-flowlog", module.private-labels.name, element(var.availability_zones, count.index)) }
  )

  lifecycle {
    precondition {
      condition     = var.flow_log_destination_arn != null
      error_message = "flow_log_destination_arn is required when enable_flow_log = true."
    }
    precondition {
      condition     = var.flow_log_destination_type != "cloud-watch-logs" || var.flow_log_iam_role_arn != null
      error_message = "flow_log_iam_role_arn is required when flow_log_destination_type is `cloud-watch-logs`."
    }
  }
}

##-----------------------------------------------------------------------------
## Below resources will deploy additional routes for public route tables.
## Controlled by var.enable — when false, no routes are created.
## Routes are only created when caller explicitly passes values.
##-----------------------------------------------------------------------------
resource "aws_route" "public_additional" {
  for_each = {
    for r in local.public_additional_routes_expanded :
    "${r.az_name}|${lookup(r, "destination_cidr_block", lookup(r, "destination_ipv6_cidr_block", ""))}" => r
  }
  route_table_id              = aws_route_table.public[tonumber(each.value.az_index)].id
  destination_cidr_block      = lookup(each.value, "destination_cidr_block", null)
  destination_ipv6_cidr_block = lookup(each.value, "destination_ipv6_cidr_block", null)

  gateway_id                = lookup(each.value, "gateway_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
  egress_only_gateway_id    = lookup(each.value, "egress_only_gateway_id", null)
  carrier_gateway_id        = lookup(each.value, "carrier_gateway_id", null)
  local_gateway_id          = lookup(each.value, "local_gateway_id", null)
  core_network_arn          = lookup(each.value, "core_network_arn", null)

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
  for_each = {
    for r in local.private_additional_routes_expanded :
    "${r.az_name}|${lookup(r, "destination_cidr_block", lookup(r, "destination_ipv6_cidr_block", ""))}" => r
  }

  route_table_id              = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[tonumber(each.value.az_index)].id
  destination_cidr_block      = lookup(each.value, "destination_cidr_block", null)
  destination_ipv6_cidr_block = lookup(each.value, "destination_ipv6_cidr_block", null)

  gateway_id                = lookup(each.value, "gateway_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
  egress_only_gateway_id    = lookup(each.value, "egress_only_gateway_id", null)
  carrier_gateway_id        = lookup(each.value, "carrier_gateway_id", null)
  local_gateway_id          = lookup(each.value, "local_gateway_id", null)
  core_network_arn          = lookup(each.value, "core_network_arn", null)

  timeouts {
    create = "5m"
  }
}

##-----------------------------------------------------------------------------
## Non-blocking security hint: warns when private subnets accept all inbound
## traffic from anywhere at the NACL layer (this is the module default).
##-----------------------------------------------------------------------------
check "private_acl_not_open_to_world" {
  assert {
    condition = !(local.private_count > 0 && var.enable_private_acl && anytrue([
      for r in var.private_inbound_acl_rules :
      try(r.rule_action == "allow" && r.protocol == "-1" && r.cidr_block == "0.0.0.0/0", false)
    ]))
    error_message = "Private subnet NACL allows ALL inbound traffic from 0.0.0.0/0. Restrict private_inbound_acl_rules (VPC CIDR + ephemeral ports 1024-65535 for NAT return traffic)."
  }
}
