locals {
  name        = "clouddrove"
  environment = "test"
  region      = "us-east-1"
  label_order = ["name", "environment"]
}

####----------------------------------------------------------------------------------
## Provider block added, Use the Amazon Web Services (AWS) provider to interact with the many resources supported by AWS.
####----------------------------------------------------------------------------------
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
  availability_zones  = ["${local.region}-1a", "${local.region}-1b", "${local.region}-1c"]
  vpc_id              = "vpv_id-xxxxxxx"
  type                = "public-private"
  igw_id              = "vpc_igw_id-xxxxxxx"
  cidr_block          = "10.0.0.0/16"
  enable_ipv6         = false
}
