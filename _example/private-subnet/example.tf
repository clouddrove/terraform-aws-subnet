provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source = "git::https://github.com/clouddrove/terraform-aws-vpc.git?ref=tags/0.12.1"

  name        = "vpc"
  application = "clouddrove"
  environment = "test"
  label_order = ["environment", "name", "application"]

  cidr_block = "10.0.0.0/16"
}

module "private-subnets" {
  source = "git::https://github.com/clouddrove/terraform-aws-subnet.git?ref=tags/0.12.1"

  name        = "subnets"
  application = "clouddrove"
  environment = "test"
  label_order = ["application", "environment", "name"]

  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id              = module.vpc.vpc_id
  type                = "private"
  nat_gateway_enabled = true
  cidr_block          = module.vpc.vpc_cidr_block
  public_subnet_ids   = ["subnet-XXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXX"]
}