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
## Vpc Module call.
##-----------------------------------------------------------------------------
module "vpc" {
  source                              = "clouddrove/vpc/aws"
  version                             = "2.0.5"
  name                                = "${local.name}-vpc"
  environment                         = local.environment
  label_order                         = local.label_order
  cidr_block                          = "10.0.0.0/16"
  enable_flow_log                     = true # Flow logs will be stored in cloudwatch log group. Variables passed in default.
  create_flow_log_cloudwatch_iam_role = true
  additional_cidr_block               = ["172.3.0.0/16", "172.2.0.0/16"]
  dhcp_options_domain_name            = "service.consul"
  dhcp_options_domain_name_servers    = ["127.0.0.1", "10.10.0.2"]
  assign_generated_ipv6_cidr_block    = true
}

##-----------------------------------------------------------------------------
## Subnet Module call.
## Below module will deploy only private subnet.
##-----------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-excessive-port-access
#tfsec:ignore:aws-ec2-no-public-ingress-acl
module "private-subnets" {
  source              = "./../../"
  name                = "${local.name}-subnet"
  environment         = local.environment
  label_order         = local.label_order
  nat_gateway_enabled = true
  availability_zones  = ["${local.region}a", "${local.region}b", "${local.region}c"]
  vpc_id              = module.vpc.vpc_id
  type                = "private"
  cidr_block          = module.vpc.vpc_cidr_block
  ipv6_cidr_block     = module.vpc.ipv6_cidr_block
  public_subnet_ids   = ["subnet-xxxxxxx", "subnet-xxxxxxx"]
}
