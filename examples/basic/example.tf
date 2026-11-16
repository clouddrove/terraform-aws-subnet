locals {
  name        = "clouddrove"
  environment = "test"
  region      = "us-east-1"
  label_order = ["name", "environment"]
}

provider "aws" {
  region = local.region
}

##-----------------------------------------------------------------------------
## Subnet Module Call.
## Both private and public subnet will be deployed.
##-----------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-excessive-port-access
#tfsec:ignore:aws-ec2-no-public-ingress-acl
module "subnets" {
  source              = "./../../"
  name                = "${local.name}-subnet"
  environment         = local.environment
  label_order         = local.label_order
  nat_gateway_enabled = true
  availability_zones  = ["${local.region}a", "${local.region}b", "${local.region}c"]
  vpc_id              = "vpc-xxxxxxxx"
  type                = "public-private"
  igw_id              = "igw-xxxxxxxx"
  cidr_block          = "10.0.0.0/16"
  enable_ipv6         = false
}
