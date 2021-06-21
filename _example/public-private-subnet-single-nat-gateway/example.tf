provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "0.15.0"

  name        = "vpc"
  environment = "test"
  label_order = ["name", "environment"]

  cidr_block = "10.0.0.0/16"
}

module "subnets" {
  source = "./../../"

  name        = "subnets"
  environment = "test"
  label_order = ["name", "environment"]

  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id              = module.vpc.vpc_id
  type                = "public-private"
  igw_id              = module.vpc.igw_id
  nat_gateway_enabled = true
  cidr_block          = module.vpc.vpc_cidr_block
  ipv6_cidr_block     = module.vpc.ipv6_cidr_block
  single_nat_gateway  = true
}