provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "0.15.1"

  name        = "vpc"
  environment = "example"
  label_order = ["name", "environment"]

  cidr_block = "10.0.0.0/16"
}

module "subnets" {
  source = "./../../"

  nat_gateway_enabled = true
  single_nat_gateway  = true

  name        = "subnets"
  environment = "example"
  label_order = ["name", "environment"]

  availability_zones              = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id                          = module.vpc.vpc_id
  type                            = "public-private"
  igw_id                          = module.vpc.igw_id
  cidr_block                      = module.vpc.vpc_cidr_block
  ipv6_cidr_block                 = module.vpc.ipv6_cidr_block
  assign_ipv6_address_on_creation = false

}
