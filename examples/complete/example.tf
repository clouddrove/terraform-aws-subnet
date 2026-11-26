provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name        = "app"
  environment = "test"
  region      = "ca-central-1"
  az_ids      = slice(data.aws_availability_zones.available.zone_ids, 0, 2)
}

##-----------------------------------------------------------------------------
## VPC Module call.
##-----------------------------------------------------------------------------
module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "2.0.0"

  enable      = true
  name        = local.name
  environment = local.environment

  cidr_block                          = "10.0.0.0/16"
  enable_flow_log                     = true
  create_flow_log_cloudwatch_iam_role = true
  additional_cidr_block               = ["172.3.0.0/16", "172.2.0.0/16"]
  dhcp_options_domain_name            = "service.consul"
  dhcp_options_domain_name_servers    = ["127.0.0.1", "10.10.0.2"]
  assign_generated_ipv6_cidr_block    = true
}

##-----------------------------------------------------------------------------
## EIP & VPN Gateway for complete example.
##-----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${local.name}-${local.environment}-nat-eip"
    Environment = local.environment
  }
}

resource "aws_vpn_gateway" "this" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name        = "${local.name}-${local.environment}-vgw"
    Environment = local.environment
  }
}

##-----------------------------------------------------------------------------
## Subnet Module call.
## Deploys public + private subnets across 2 AZ IDs with:
##   - Dual-stack IPv6 + EIGW + DNS64 + NAT64
##   - External EIP reuse + single NAT Gateway
##   - Network ACL rules & VGW route propagation
##   - Custom route table entries & per-AZ/common tags
##-----------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-excessive-port-access
#tfsec:ignore:aws-ec2-no-public-ingress-acl
module "subnets" {
  source = "./../../"

  enable      = true
  name        = local.name
  environment = local.environment
  region      = local.region

  ##---------------------------------------------------------------------------
  ## Subnet configuration.
  ##---------------------------------------------------------------------------
  nat_gateway_enabled                                           = true
  single_nat_gateway                                            = true
  reuse_nat_ips                                                 = true
  external_nat_ip_ids                                           = [aws_eip.nat.id]
  availability_zone_ids                                         = local.az_ids
  vpc_id                                                        = module.vpc.vpc_id
  type                                                          = "public-private"
  igw_id                                                        = module.vpc.igw_id
  enable_eigw                                                   = true
  eigw_id                                                       = module.vpc.ipv6_egress_only_igw_id
  cidr_block                                                    = module.vpc.vpc_cidr_block
  ipv6_cidr_block                                               = module.vpc.ipv6_cidr_block
  enable_ipv6                                                   = true
  public_subnet_assign_ipv6_address_on_creation                 = true
  private_subnet_assign_ipv6_address_on_creation                = true
  public_subnet_enable_dns64                                    = true
  private_subnet_enable_dns64                                   = true
  enable_nat64                                                  = true
  public_subnet_enable_resource_name_dns_aaaa_record_on_launch  = true
  private_subnet_enable_resource_name_dns_aaaa_record_on_launch = true
  public_propagating_vgws                                       = [aws_vpn_gateway.this.id]
  private_propagating_vgws                                      = [aws_vpn_gateway.this.id]

  tags = {
    Example = "complete"
  }

  public_subnet_tags_per_az = {
    (local.az_ids[0]) = {
      Tier = "public-primary"
    }
  }

  private_subnet_tags_per_az = {
    (local.az_ids[0]) = {
      Tier = "private-primary"
    }
  }

  ##---------------------------------------------------------------------------
  ## Network ACL rules.
  ##---------------------------------------------------------------------------
  private_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = module.vpc.vpc_cidr_block
    }
  ]
  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = module.vpc.vpc_cidr_block
    }
  ]

  ##---------------------------------------------------------------------------
  ## Custom Route Table entries.
  ##---------------------------------------------------------------------------
  additional_public_routes_for_all = [
    {
      destination_cidr_block = "10.100.0.0/16"
      gateway_id             = aws_vpn_gateway.this.id
    }
  ]

  additional_public_routes_per_subnet = {
    (local.az_ids[0]) = [
      {
        destination_cidr_block = "192.168.1.0/24"
        gateway_id             = aws_vpn_gateway.this.id
      }
    ]
    (local.az_ids[1]) = [
      {
        destination_cidr_block = "192.168.2.0/24"
        gateway_id             = aws_vpn_gateway.this.id
      }
    ]
  }

  additional_private_routes_for_all = [
    {
      destination_cidr_block = "10.100.0.0/16"
      gateway_id             = aws_vpn_gateway.this.id
    }
  ]
}
