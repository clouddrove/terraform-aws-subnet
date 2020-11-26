provider "aws" {
  region = "eu-west-1"
}
/*
module "vpc" {
  source = "git::https://github.com/clouddrove/terraform-aws-vpc.git?ref=tags/0.12.4"

  name        = "vpc"
  application = "clouddrove"
  environment = "test"
  label_order = ["environment", "application", "name"]

  cidr_block = "10.0.0.0/16"
}*/

module "private-subnets" {
  source = "./../../"

  name        = "subnets"
  application = "clouddrove"
  environment = "test"
  label_order = ["environment", "application", "name"]

  availability_zones  = ["eu-west-1a", "eu-west-1b"]
  vpc_id              = "vpc-0e662cbdfa54ca7ac"
  type                = "private"
  nat_gateway_enabled = false
  cidr_block          = "10.0.0.0/16"
  ipv6_cidr_block     = "2a05:d018:d72:8700::/56"
  public_subnet_ids   = ["subnet-xxxxxxxxxxx", "subnet-xxxxxxxxxxxx"]
  ipv6_cidrs          = ["2a05:d018:d72:8706::/64","2a05:d018:d72:8707::/64"]
  ipv4_cidrs          = ["10.0.192.0/19","10.0.224.0/19"]
}