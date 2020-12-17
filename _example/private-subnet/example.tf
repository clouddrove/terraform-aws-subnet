provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "0.13.0"

  name        = "vpc"
  repository  = "https://registry.terraform.io/modules/clouddrove/vpc/aws/0.14.0"
  environment = "test"
  label_order = ["name", "environment"]

  cidr_block = "10.0.0.0/16"
}

module "private-subnets" {
  source = "./../../"

  name        = "subnets"
  repository  = "https://registry.terraform.io/modules/clouddrove/subnet/aws/0.14.0"
  environment = "test"
  label_order = ["name", "environment"]

  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id              = module.vpc.vpc_id
  type                = "private"
  nat_gateway_enabled = true
  cidr_block          = module.vpc.vpc_cidr_block
  ipv6_cidr_block     = module.vpc.ipv6_cidr_block
  public_subnet_ids   = ["subnet-XXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXX"]
}