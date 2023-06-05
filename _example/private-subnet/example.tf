provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "1.3.1"

  name        = "vpc"
  environment = "test"
  label_order = ["name", "environment"]

  cidr_block = "10.0.0.0/16"
}

module "private-subnets" {
  source = "./../../"

  name        = "subnets"
  environment = "test"
  label_order = ["name", "environment"]

  nat_gateway_enabled = true

  availability_zones              = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id                          = module.vpc.vpc_id
  type                            = "private"
  cidr_block                      = module.vpc.vpc_cidr_block
  ipv6_cidr_block                 = module.vpc.ipv6_cidr_block
  public_subnet_ids               = ["subnet-xxxxxxxxxxxx", "subnet-xxxxxxxxxxxx"]
  assign_ipv6_address_on_creation = false

}
