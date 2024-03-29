locals {
  name        = "app"
  environment = "test"
}

##----------------------------------------------------------------------------- 
## Subnet Module Call. 
## Both private and public subnet will be deployed.     
##-----------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-excessive-port-access 
#tfsec:ignore:aws-ec2-no-public-ingress-acl
module "subnets" {
  source              = "./../../"
  name                = local.name
  environment         = local.environment
  nat_gateway_enabled = true
  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id              = "vpv_id-xxxxxxx"
  type                = "public-private"
  igw_id              = "vpc_igw_id-xxxxxxx"
  cidr_block          = "10.0.0.0/16"
  enable_ipv6         = false
}