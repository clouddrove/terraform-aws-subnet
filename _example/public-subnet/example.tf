provider "aws" {
  region = "us-east-1"
}

locals {
  name        = "app"
  environment = "test"
}

##----------------------------------------------------------------------------- 
## Vpc Module call.    
##-----------------------------------------------------------------------------
module "vpc" {
  source                              = "clouddrove/vpc/aws"
  version                             = "2.0.0"
  name                                = local.name
  environment                         = local.environment
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
## Below module will deploy only public subnet.  
##-----------------------------------------------------------------------------
module "subnets" {
  source             = "./../../"
  name               = local.name
  environment        = local.environment
  label_order        = ["name", "environment"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_id             = module.vpc.vpc_id
  type               = "public"
  igw_id             = module.vpc.igw_id
  cidr_block         = module.vpc.vpc_cidr_block
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
  enable_ipv6        = true
}
