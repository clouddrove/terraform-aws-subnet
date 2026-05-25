provider "aws" {
  region = local.region
}

locals {
  name        = "app"
  environment = "test"
  region      = "eu-west-1"
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
## VPN Gateway — used as route target in the examples below.
## Replace gateway_id with your actual target resource ID
## (transit_gateway_id, vpc_peering_connection_id, etc.)
##-----------------------------------------------------------------------------
resource "aws_vpn_gateway" "this" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name        = "${local.name}-${local.environment}-vgw"
    Environment = local.environment
  }
}

##-----------------------------------------------------------------------------
## Subnet Module call.
## Deploys public + private subnets across 3 AZs with:
##   - IPv6 support
##   - Network ACL rules
##   - Custom route table entries
##-----------------------------------------------------------------------------
#tfsec:ignore:aws-ec2-no-excessive-port-access
#tfsec:ignore:aws-ec2-no-public-ingress-acl
module "subnets" {
  source = "./../../"

  enable      = true
  name        = local.name
  environment = local.environment

  ##---------------------------------------------------------------------------
  ## Subnet configuration.
  ##---------------------------------------------------------------------------
  nat_gateway_enabled                            = true
  single_nat_gateway                             = true
  availability_zones                             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  vpc_id                                         = module.vpc.vpc_id
  type                                           = "public-private"
  igw_id                                         = module.vpc.igw_id
  cidr_block                                     = module.vpc.vpc_cidr_block
  ipv6_cidr_block                                = module.vpc.ipv6_cidr_block
  public_subnet_assign_ipv6_address_on_creation  = true
  enable_ipv6                                    = true
  private_subnet_assign_ipv6_address_on_creation = true

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
  ##
  ## Two modes — use either or both:
  ##
  ## Mode 1 — for_all:
  ##   Adds the same route to every AZ's route table.
  ##   Use when all subnets need identical routing.
  ##
  ## Mode 2 — per_subnet:
  ##   Adds different routes to specific AZs only.
  ##   Key must be the exact AZ name string (e.g. "eu-west-1a").
  ##   AZs not listed here are untouched.
  ##
  ## Both modes are optional — omitting either adds no extra routes.
  ## All routes are removed when enable = false.
  ##
  ## Supported target keys (set only ONE per route entry):
  ##   gateway_id              — Internet Gateway or VPN Gateway
  ##   nat_gateway_id          — NAT Gateway
  ##   transit_gateway_id      — Transit Gateway
  ##   vpc_peering_connection_id — VPC Peering Connection
  ##   network_interface_id    — Elastic Network Interface
  ##   egress_only_gateway_id  — Egress-Only Internet Gateway (IPv6)
  ##   carrier_gateway_id      — Carrier Gateway
  ##   local_gateway_id        — Local Gateway (Outposts)
  ##   core_network_arn        — Cloud WAN Core Network
  ##---------------------------------------------------------------------------

  # Mode 1: Same route added to ALL public route tables.
  # eu-west-1a, eu-west-1b and eu-west-1c all get this entry.
  additional_public_routes_for_all = [
    {
      destination_cidr_block = "10.100.0.0/16"
      gateway_id             = aws_vpn_gateway.this.id
    }
  ]

  # Mode 2: Different route per specific public subnet.
  # AZ key must match exactly what is passed in availability_zones.
  # Using local.region ensures one place to change the region.

  additional_public_routes_per_subnet = {
    "${local.region}a" = [
      {
        destination_cidr_block = "192.168.1.0/24"
        gateway_id             = aws_vpn_gateway.this.id
      }
    ]
    "${local.region}b" = [
      {
        destination_cidr_block = "192.168.2.0/24"
        gateway_id             = aws_vpn_gateway.this.id
      }
    ]
  }

  # Mode 1: Same route added to ALL private route tables.
  additional_private_routes_for_all = [
    {
      destination_cidr_block = "10.100.0.0/16"
      gateway_id             = aws_vpn_gateway.this.id
    }
  ]

  # Mode 2: Different route per specific private subnet.
  # Only eu-west-1a will get this extra entry.
  # eu-west-1b and eu-west-1c only get the for_all route above.
  additional_private_routes_per_subnet = {
    "${local.region}a" = [
      {
        destination_cidr_block = "192.168.10.0/24"
        gateway_id             = aws_vpn_gateway.this.id
      }
    ]
  }
}