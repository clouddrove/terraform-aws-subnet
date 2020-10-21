provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "0.13.0"

  name        = "vpc"
  application = "clouddrove"
  environment = "test"
  label_order = ["environment", "application", "name"]

  cidr_block = "10.0.0.0/16"
}

module "subnets" {
  source = "./../../"

  name        = "subnets"
  application = "clouddrove"
  environment = "test"
  label_order = ["environment", "application", "name"]

  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id             = module.vpc.vpc_id
  type               = "public"
  igw_id             = module.vpc.igw_id
  cidr_block         = module.vpc.vpc_cidr_block
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}