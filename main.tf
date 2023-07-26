# Managed By : CloudDrove 
# Copyright @ CloudDrove. All Right Reserved.

##----------------------------------------------------------------------------- 
## Locals declration to determine count of public subnet, private subnet, and nat gateway. 
##-----------------------------------------------------------------------------
locals {
  public_count      = var.enable == true && (var.type == "public" || var.type == "public-private") ? length(var.availability_zones) : 0
  private_count     = var.enable == true && (var.type == "private" || var.type == "public-private") ? length(var.availability_zones) : 0
  nat_gateway_count = var.single_nat_gateway ? 1 : (var.enable == true && (var.type == "private" || var.type == "public-private") && var.nat_gateway_enabled == true ? length(var.availability_zones) : 0)
}
##----------------------------------------------------------------------------- 
## Labels module called that will be used for naming and tags.   
##-----------------------------------------------------------------------------
module "private-labels" {
  source  = "clouddrove/labels/aws"
  version = "1.3.0"

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
  version = "1.3.0"

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
  cidr_block                                     = length(var.ipv4_public_cidrs) == 0 ? cidrsubnet(var.cidr_block, ceil(log(local.public_count * 2, 2)), local.public_count + count.index) : var.ipv4_public_cidrs[count.index]
  ipv6_cidr_block                                = var.enable_ipv6 ? (length(var.public_ipv6_cidrs) == 0 ? cidrsubnet(var.ipv6_cidr_block, 8, local.public_count + count.index) : var.public_ipv6_cidrs[count.index]) : null
  map_public_ip_on_launch                        = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.public_subnet_ipv6_native ? true : var.public_subnet_assign_ipv6_address_on_creation
  private_dns_hostname_type_on_launch            = var.public_subnet_private_dns_hostname_type_on_launch
  ipv6_native                                    = var.enable_ipv6 && var.public_subnet_ipv6_native
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.public_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.public_subnet_ipv6_native && var.public_subnet_enable_resource_name_dns_a_record_on_launch
  enable_dns64                                   = var.enable_ipv6 && var.public_subnet_enable_dns64
  tags = merge(
    module.public-labels.tags, var.tags,
    {
      "Name" = format("%s%s%s", module.public-labels.id, var.delimiter, element(var.availability_zones, count.index))
      "AZ"   = element(var.availability_zones, count.index)
    }
  )
  lifecycle {
    # Ignore tags added by kubernetes
    ignore_changes = [
      tags,
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
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.public.*.id
  tags       = module.public-labels.tags
  depends_on = [aws_subnet.public]
}

resource "aws_network_acl_rule" "public_inbound" {
  count           = var.enable && local.public_count > 0 && var.enable_public_acl && (var.type == "public" || var.type == "public-private") ? length(var.public_inbound_acl_rules) : 0
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
    module.public-labels.tags,
    {
      "Name" = format("%s%s%s-rt", module.public-labels.id, var.delimiter, element(var.availability_zones, count.index))
      "AZ"   = element(var.availability_zones, count.index)
    }
  )
}

resource "aws_route" "public" {
  count                  = local.public_count
  route_table_id         = element(aws_route_table.public.*.id, count.index)
  gateway_id             = var.igw_id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.public]
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_ipv6" {
  count                       = local.public_count
  route_table_id              = element(aws_route_table.public.*.id, count.index)
  gateway_id                  = var.igw_id
  destination_ipv6_cidr_block = "::/0"
  depends_on                  = [aws_route_table.public]
}

resource "aws_route_table_association" "public" {
  count          = local.public_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
  depends_on = [
    aws_subnet.public,
    aws_route_table.public,
  ]
}

##----------------------------------------------------------------------------- 
## Below resource will deploy flow logs for public subnet. 
##-----------------------------------------------------------------------------
resource "aws_flow_log" "public_subnet_flow_log" {
  count                    = var.enable && var.enable_flow_log && local.public_count > 0 ? 1 : 0
  log_destination_type     = var.flow_log_destination_type
  log_destination          = var.flow_log_destination_arn
  log_format               = var.flow_log_log_format
  iam_role_arn             = var.flow_log_iam_role_arn
  traffic_type             = var.flow_log_traffic_type
  subnet_id                = element(aws_subnet.public.*.id, count.index)
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
    module.public-labels.tags,
    {
      "Name" = format("%s-flowlog", module.public-labels.name)
    }
  )
}

##----------------------------------------------------------------------------- 
## Below resource will deploy private subnets and its related components in aws environment.     
##-----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count                                          = local.private_count
  vpc_id                                         = var.vpc_id
  availability_zone                              = element(var.availability_zones, count.index)
  cidr_block                                     = length(var.ipv4_private_cidrs) == 0 ? cidrsubnet(var.cidr_block, local.public_count == 0 ? ceil(log(local.private_count * 2, 2)) : ceil(log(local.public_count * 2, 2)), count.index) : var.ipv4_private_cidrs[count.index]
  ipv6_cidr_block                                = var.enable_ipv6 ? (length(var.private_ipv6_cidrs) == 0 ? cidrsubnet(var.ipv6_cidr_block, 8, local.public_count + count.index) : var.private_ipv6_cidrs[count.index]) : null
  map_public_ip_on_launch                        = var.map_private_ip_on_launch
  assign_ipv6_address_on_creation                = var.enable_ipv6 && var.private_subnet_ipv6_native ? true : var.private_subnet_assign_ipv6_address_on_creation
  private_dns_hostname_type_on_launch            = var.private_subnet_private_dns_hostname_type_on_launch
  ipv6_native                                    = var.enable_ipv6 && var.private_subnet_ipv6_native
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_ipv6 && var.private_subnet_enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = !var.private_subnet_ipv6_native && var.private_subnet_enable_resource_name_dns_a_record_on_launch
  enable_dns64                                   = var.enable_ipv6 && var.private_subnet_enable_dns64

  tags = merge(
    module.private-labels.tags,
    {
      "Name" = format("%s%s%s", module.private-labels.id, var.delimiter, element(var.availability_zones, count.index))
      "AZ"   = element(var.availability_zones, count.index)
    },
    var.tags
  )

  lifecycle {
    # Ignore tags added by kubernetes
    ignore_changes = [
      tags,
      tags["kubernetes.io"],
      tags["SubnetType"],
    ]
  }
}

##----------------------------------------------------------------------------- 
## Below resource will deploy network acl and its rules that will be attached to private subnets.     
##-----------------------------------------------------------------------------
resource "aws_network_acl" "private" {
  count      = var.enable && var.enable_private_acl && (var.type == "private" || var.type == "public-private") ? 1 : 0
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.private.*.id
  tags       = module.private-labels.tags
  depends_on = [aws_subnet.private]
}

resource "aws_network_acl_rule" "private_inbound" {
  count           = var.enable && var.enable_private_acl && (var.type == "private" || var.type == "public-private") ? length(var.private_inbound_acl_rules) : 0
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
  count           = var.enable && var.enable_private_acl && (var.type == "private" || var.type == "public-private") ? length(var.private_inbound_acl_rules) : 0
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
  count  = local.private_count
  vpc_id = var.vpc_id
  tags = merge(
    module.private-labels.tags,
    {
      "Name" = format("%s%s%s-rt", module.private-labels.id, var.delimiter, element(var.availability_zones, count.index))
      "AZ"   = element(var.availability_zones, count.index)
    }
  )
}

resource "aws_route_table_association" "private" {
  count          = local.private_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, var.single_nat_gateway ? 0 : count.index, )
}

resource "aws_route" "nat_gateway" {
  count                  = local.nat_gateway_count > 0 ? local.nat_gateway_count : 0
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.private.*.id, count.index)
  depends_on             = [aws_route_table.private]
}

##----------------------------------------------------------------------------------
## Below resource will create Elastic IP (EIP) for nat gateway. 
##----------------------------------------------------------------------------------
resource "aws_eip" "private" {
  count  = local.nat_gateway_count
  domain = "vpc"
  tags = merge(
    module.private-labels.tags,
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
  count         = local.nat_gateway_count
  allocation_id = element(aws_eip.private.*.id, count.index)
  subnet_id     = length(aws_subnet.public) > 0 ? element(aws_subnet.public.*.id, count.index) : element(var.public_subnet_ids, count.index)
  tags = merge(
    module.private-labels.tags,
    {
      "Name" = format("%s%s%s-nat-gateway", module.private-labels.id, var.delimiter, element(var.availability_zones, count.index))
    }
  )
}

##----------------------------------------------------------------------------- 
## Below resource will deploy flow logs for private subnet. 
##-----------------------------------------------------------------------------
resource "aws_flow_log" "private_subnet_flow_log" {
  count                    = var.enable && var.enable_flow_log && local.private_count > 0 ? 1 : 0
  log_destination_type     = var.flow_log_destination_type
  log_destination          = var.flow_log_destination_arn
  log_format               = var.flow_log_log_format
  iam_role_arn             = var.flow_log_iam_role_arn
  traffic_type             = var.flow_log_traffic_type
  subnet_id                = element(aws_subnet.private.*.id, count.index)
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
    module.private-labels.tags,
    {
      "Name" = format("%s-flowlog", module.private-labels.name)
    }
  )
}
