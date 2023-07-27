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
  dhcp_options_domain_name            = "service.consul"
  dhcp_options_domain_name_servers    = ["127.0.0.1", "10.10.0.2"]
  assign_generated_ipv6_cidr_block    = true
}

##----------------------------------------------------------------------------- 
## Subnet Module call.
## Below module will deploy only public subnet.  
##-----------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-excessive-port-access 
#tfsec:ignore:aws-ec2-no-public-ingress-acl
module "subnets" {
  source             = "./../../"
  name               = local.name
  environment        = local.environment
  label_order        = ["name", "environment"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_id             = module.vpc.vpc_id
  type               = "public"
  igw_id             = module.vpc.igw_id
  ipv4_public_cidrs  = ["10.0.1.0/24", "10.0.13.0/24", "10.0.18.0/24"]
  enable_ipv6        = false
}
