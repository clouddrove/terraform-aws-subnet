####----------------------------------------------------------------------------------
## Provider block added, Use the Amazon Web Services (AWS) provider to interact with the many resources supported by AWS.
####----------------------------------------------------------------------------------
provider "aws" {
  region = "eu-west-1"
}
data "aws_region" "current" {}
####----------------------------------------------------------------------------------
## A VPC is a virtual network that closely resembles a traditional network that you'd operate in your own data center.
####----------------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "1.3.1"

  name        = "vpc"
  environment = "test"
  label_order = ["name", "environment"]

  cidr_block      = "10.0.0.0/16"
  enable_flow_log = false
}
####----------------------------------------------------------------------------------
## Subnet is a range of IP addresses in your VPC.
####----------------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-public-ip-subnet
module "subnets" {
  source = "./../../"

  name        = "subnets"
  environment = "test"
  label_order = ["name", "environment"]

  nat_gateway_enabled             = true
  availability_zones              = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id                          = module.vpc.vpc_id
  type                            = "public-private"
  igw_id                          = module.vpc.igw_id
  cidr_block                      = module.vpc.vpc_cidr_block
  ipv6_cidr_block                 = module.vpc.ipv6_cidr_block
  assign_ipv6_address_on_creation = false
  enable_vpc_endpoint             = true
  service_name                    = "com.amazonaws.${data.aws_region.current.name}.ec2" ## The service name can be changed according to the service.
  endpoint_policy                 = data.aws_iam_policy_document.vpc_endpoint_policy.json
}

data "aws_iam_policy_document" "vpc_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["ec2:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [module.vpc.vpc_id]
    }
  }
}
