##----------------------------------------------------------------------------- 
## Subnet Module Call. 
## Both private and public subnet will be deployed.     
##-----------------------------------------------------------------------------
module "subnets" {
  source              = "./../../"
  name                = "subnets"
  environment         = "test"
  nat_gateway_enabled = true
  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id              = "vpv_id-------"
  type                = "public-private"
  igw_id              = "vpc_igw_id---"
  cidr_block          = "10.0.0.0/16"
  enable_ipv6         = false
}