## Managed By : CloudDrove
## Copyright @ CloudDrove. All Right Reserved.

#Module      : label
#Description : Terraform module to create consistent naming for multiple names.
locals {
  public_count               = "${var.enabled == "true" && (var.type == "public" || var.type == "public-private") ? length(var.availability_zones) : 0}"
  private_nat_gateways_count = "${var.enabled == "true" && (var.type == "private" || var.type == "public-private") && var.nat_gateway_enabled == "true" ? length(var.availability_zones) : 0}"
  private_count              = "${var.enabled == "true" && (var.type == "private" || var.type == "public-private") ? length(var.availability_zones) : 0}"
}

module "lables" {
  source      = "git::https://github.com/clouddrove/terraform-lables.git?ref=tags/0.11.0"
  name        = "${var.name}"
  application = "${var.application}"
  environment = "${var.environment}"
}

#Module      : PUBLIC SUBNET
#Description : Terraform module which creates Subnet resources on AWS
resource "aws_subnet" "public" {
  count             = "${local.public_count}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  cidr_block        = "${cidrsubnet(signum(length(var.cidr_block)) == 1 ? var.cidr_block : var.cidr_block, ceil(log(local.public_count * 2, 2)), local.public_count + count.index)}"

  tags = "${
    merge(
      module.lables.tags,
      map(
        "Name", "public-${module.lables.id}${var.delimiter}${element(var.availability_zones, count.index)}",
        "AZ", "${element(var.availability_zones, count.index)}"
      )
    )
  }"

  lifecycle {
    # Ignore tags added by kops or kubernetes
    ignore_changes = ["tags.%", "tags.kubernetes", "tags.SubnetType"]
  }
}

#Module      : NETWORK ACL
#Description : Provides an network ACL resource. You might set up network ACLs with rules similar to your
#              security groups in order to add an additional layer of security to your VPC.
resource "aws_network_acl" "public" {
  count      = "${var.enabled == "true" && (var.type == "public" || var.type == "public-private") && signum(length(var.public_network_acl_id)) == 0 ? 1 : 0}"
  vpc_id     = "${var.vpc_id}"
  subnet_ids = ["${aws_subnet.public.*.id}"]
  egress     = "${var.public_network_acl_egress}"
  ingress    = "${var.public_network_acl_ingress}"
  tags       = "${module.lables.tags}"
  depends_on = ["aws_subnet.public"]
}

#Module      : ROUTE TABLE
#Description : Provides a resource to create a VPC routing table.
resource "aws_route_table" "public" {
  count  = "${local.public_count}"
  vpc_id = "${var.vpc_id}"

  tags = "${
    merge(
      module.lables.tags,
      map(
        "Name", "${module.lables.id}${var.delimiter}${element(var.availability_zones, count.index)}",
        "AZ", "${element(var.availability_zones, count.index)}"
      )
    )
  }"
}

#Module      : ROUTE
#Description : Provides a resource to create a routing table entry (a route) in a VPC routing table.
resource "aws_route" "public" {
  count                  = "${local.public_count}"
  route_table_id         = "${element(aws_route_table.public.*.id, count.index)}"
  gateway_id             = "${var.igw_id}"
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = ["aws_route_table.public"]
}

#Module      : ROUTE TABLE ASSOCIATION PRIVATE
#Description : Provides a resource to create an association between a subnet and routing table.
resource "aws_route_table_association" "public" {
  count          = "${local.public_count}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
  depends_on     = ["aws_subnet.public", "aws_route_table.public"]
}

#Module      : Flow Log
#Description : Provides a VPC/Subnet/ENI Flow Log to capture IP traffic for a specific network interface, subnet, or VPC. Logs are sent to a CloudWatch Log Group or a S3 Bucket.
resource "aws_flow_log" "subnet_flow_log" {
  count                = "${var.subnet_flow_log == "true" ? 1 : 0}"
  log_destination      = "${var.s3_bucket_arn}"
  log_destination_type = "s3"
  traffic_type         = "${var.traffic_type}"
  subnet_id            = "${element(aws_subnet.public.*.id, count.index)}"
}

#Module      : PRIVATE SUBNET
#Description : Terraform module which creates Subnet resources on AWS
resource "aws_subnet" "private" {
  count             = "${local.private_count}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  cidr_block        = "${cidrsubnet(signum(length(var.cidr_block)) == 1 ? var.cidr_block : var.cidr_block, ceil(log(local.public_count * 2, 2)), count.index)}"

  tags = "${
    merge(
      module.lables.tags,
      map(
        "Name", "private-${module.lables.id}${var.delimiter}${element(var.availability_zones, count.index)}",
        "AZ", "${element(var.availability_zones, count.index)}"
      )
    )
  }"
}

#Module      : NETWORK ACL
#Description : Provides an network ACL resource. You might set up network ACLs with rules similar to your
#              security groups in order to add an additional layer of security to your VPC.
resource "aws_network_acl" "private" {
  count      = "${var.enabled == "true" && (var.type == "private" || var.type == "public-private") && signum(length(var.public_network_acl_id)) == 0 ? 1 : 0}"
  vpc_id     = "${var.vpc_id}"
  subnet_ids = ["${aws_subnet.private.*.id}"]
  egress     = "${var.public_network_acl_egress}"
  ingress    = "${var.public_network_acl_ingress}"
  tags       = "${module.lables.tags}"
  depends_on = ["aws_subnet.private"]
}

#Module      : ROUTE TABLE
#Description : Provides a resource to create a VPC routing table.
resource "aws_route_table" "private" {
  count  = "${local.private_count}"
  vpc_id = "${var.vpc_id}"

  tags = "${
    merge(
      module.lables.tags,
      map(
        "Name", "${module.lables.id}${var.delimiter}${element(var.availability_zones, count.index)}",
        "AZ", "${element(var.availability_zones, count.index)}"
      )
    )
  }"
}

#Module      : ROUTE TABLE ASSOCIATION PRIVATE
#Description : Provides a resource to create an association between a subnet and routing table.
resource "aws_route_table_association" "private" {
  count          = "${local.private_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

#Module      : ROUTE
#Description : Provides a resource to create a routing table entry (a route) in a VPC routing table.
resource "aws_route" "nat_gateway" {
  count                  = "${local.private_nat_gateways_count}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.private.*.id, count.index)}"
  depends_on             = ["aws_route_table.private"]
}

#Module      : EIP
#Description : Provides an Elastic IP resource..
resource "aws_eip" "private" {
  count = "${local.private_nat_gateways_count}"
  vpc   = true
  tags  = "${module.lables.tags}"

  lifecycle {
    create_before_destroy = true
  }
}
#Module      : NAT GATEWAY
#Description : Provides a resource to create a VPC NAT Gateway.
resource "aws_nat_gateway" "private" {
  count         = "${local.private_nat_gateways_count}"
  allocation_id = "${element(aws_eip.private.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  tags          = "${module.lables.tags}"
}

#Module      : Flow Log
#Description : Provides a VPC/Subnet/ENI Flow Log to capture IP traffic for a specific network
#              interface, subnet, or VPC. Logs are sent to a CloudWatch Log Group or a S3 Bucket.
resource "aws_flow_log" "private_subnet_flow_log" {
  count                = "${var.subnet_flow_log == "true" ? 1 : 0}"
  log_destination      = "${var.s3_bucket_arn}"
  log_destination_type = "s3"
  traffic_type         = "${var.traffic_type}"
  subnet_id            = "${element(aws_subnet.private.*.id, count.index)}"
}
