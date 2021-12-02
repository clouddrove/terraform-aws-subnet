provider "aws" {
  region = "us-east-1"
}



module "private-subnets" {
  source = "./../../"

  name        = "subnets"
  environment = "test"
  label_order = ["name", "environment"]

  nat_gateway_enabled = true

  availability_zones              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_id                          = "vpc-xxxxxxxxxxxxxxxxxxxxx"
  type                            = "private"
  cidr_block                      = "10.0.0.0/16"
  ipv6_cidr_block                 = "ffff:ffff:fff:ffff::/56"
  public_subnet_ids               = ["subnet-xxxxxxxxxxxxxx", "subnet-xxxxxxxxxxx"]
  assign_ipv6_address_on_creation = false
}
