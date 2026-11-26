mock_provider "aws" {}

variables {
  name        = "test"
  environment = "dev"
  vpc_id      = "vpc-0123456789abcdef0"
}

run "public_private_with_single_nat_and_eigw" {
  command = plan

  variables {
    type                = "public-private"
    availability_zones  = ["us-east-1a", "us-east-1b"]
    cidr_block          = "10.0.0.0/16"
    ipv6_cidr_block     = "2600:1f18:0000:0000::/56"
    enable_ipv6         = true
    igw_id              = "igw-0123456789abcdef0"
    enable_eigw         = true
    eigw_id             = "eigw-0123456789abcdef0"
    nat_gateway_enabled = true
    single_nat_gateway  = true
    tags = {
      CostCenter = "platform"
    }
    public_subnet_tags_per_az = {
      "us-east-1a" = {
        Tier = "edge-a"
      }
    }
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected 2 public and 2 private subnets."
  }

  assert {
    condition     = length(aws_nat_gateway.private) == 1 && length(aws_eip.private) == 1 && length(aws_route_table.private) == 1
    error_message = "Expected 1 NAT gateway, 1 EIP, and 1 shared private route table."
  }

  assert {
    condition     = length(aws_route.private_ipv6) == 1 && aws_route.private_ipv6[0].egress_only_gateway_id == "eigw-0123456789abcdef0"
    error_message = "Expected private IPv6 route to target EIGW."
  }

  assert {
    condition     = aws_subnet.public[0].tags["CostCenter"] == "platform" && aws_subnet.public[0].tags["Tier"] == "edge-a"
    error_message = "Expected common and per-AZ tags on public subnet."
  }
}

run "single_nat_flag_with_nat_disabled_keeps_per_az_routes" {
  command = plan

  variables {
    type                = "private"
    availability_zones  = ["us-east-1a", "us-east-1b"]
    cidr_block          = "10.0.0.0/16"
    nat_gateway_enabled = false
    single_nat_gateway  = true
    additional_private_routes_for_all = [
      {
        destination_cidr_block = "10.100.0.0/16"
        transit_gateway_id     = "tgw-0123456789abcdef0"
      }
    ]
  }

  assert {
    condition     = length(aws_route_table.private) == 2 && length(aws_route.private_additional) == 2
    error_message = "Expected 2 private route tables and additional route applied to both when NAT is disabled."
  }
}

run "ipam_mixed_dual_stack_public_and_ipv6_only_private_with_nat64" {
  command = plan

  variables {
    type                        = "public-private"
    availability_zone_ids       = ["use1-az1", "use1-az2"]
    ipv4_ipam_pool_id           = "ipam-pool-0123456789abcdef0"
    ipv4_netmask_length         = 24
    ipv6_ipam_pool_id           = "ipam-pool-fedcba9876543210f"
    ipv6_netmask_length         = 64
    enable_ipv6                 = true
    private_subnet_ipv6_native  = true
    private_subnet_enable_dns64 = true
    nat_gateway_enabled         = true
    enable_nat64                = true
    igw_id                      = "igw-0123456789abcdef0"
  }

  assert {
    condition     = aws_subnet.public[0].availability_zone_id == "use1-az1" && aws_subnet.public[0].ipv4_ipam_pool_id == "ipam-pool-0123456789abcdef0"
    error_message = "Expected public subnet to use AZ ID and IPv4 IPAM pool."
  }

  assert {
    condition     = aws_subnet.private[0].ipv6_native == true && aws_subnet.private[0].ipv4_ipam_pool_id == null
    error_message = "Expected private subnet to be IPv6-native with no IPv4 IPAM pool."
  }

  assert {
    condition     = length(aws_route.nat_gateway) == 0 && length(aws_route.nat64) == 2
    error_message = "Expected NAT64 routes for IPv6-native private subnets and no IPv4 NAT routes."
  }
}

run "regional_nat_gateway_and_outpost_subnet" {
  command = plan

  variables {
    type                                           = "private"
    availability_zones                             = ["us-east-1a", "us-east-1b"]
    cidr_block                                     = "10.2.0.0/16"
    nat_gateway_enabled                            = true
    nat_gateway_availability_mode                  = "regional"
    private_subnet_outpost_arn                     = "arn:aws:outposts:us-east-1:123456789012:outpost/op-0123456789abcdef0"
    private_subnet_customer_owned_ipv4_pool        = "ipv4pool-coip-0123456789abcdef0"
    private_subnet_map_customer_owned_ip_on_launch = true
    private_subnet_enable_lni_at_device_index      = 1
    additional_private_routes_per_subnet = {
      "us-east-1a" = [
        {
          destination_prefix_list_id = "pl-0123456789abcdef0"
          transit_gateway_id         = "tgw-0123456789abcdef0"
        },
        {
          destination_cidr_block = "192.168.100.0/24"
          vpc_endpoint_id        = "vpce-0123456789abcdef0"
        }
      ]
    }
  }

  assert {
    condition     = length(aws_nat_gateway.private) == 1 && aws_nat_gateway.private[0].availability_mode == "regional" && length(aws_eip.private) == 0
    error_message = "Expected 1 regional NAT gateway without module-managed EIPs."
  }

  assert {
    condition     = length(aws_route.nat_gateway) == 2 && length(aws_route.private_additional) == 2
    error_message = "Expected both private route tables to route to the regional NAT gateway plus both additional routes."
  }

  assert {
    condition     = aws_subnet.private[0].outpost_arn != null && aws_subnet.private[0].enable_lni_at_device_index == 1 && aws_subnet.private[0].map_customer_owned_ip_on_launch == true
    error_message = "Expected Outpost, CoIP, and LNI attributes on private subnets."
  }
}

run "reuse_external_nat_ips_and_firehose_flow_log" {
  command = plan

  variables {
    type                      = "public-private"
    availability_zones        = ["us-east-1a", "us-east-1b"]
    cidr_block                = "10.3.0.0/16"
    igw_id                    = "igw-0123456789abcdef0"
    nat_gateway_enabled       = true
    reuse_nat_ips             = true
    external_nat_ip_ids       = ["eipalloc-11111111111111111", "eipalloc-22222222222222222"]
    enable_flow_log           = true
    flow_log_destination_type = "kinesis-data-firehose"
    flow_log_destination_arn  = "arn:aws:firehose:us-east-1:123456789012:deliverystream/vpc-flow"
  }

  assert {
    condition     = length(aws_eip.private) == 0 && aws_nat_gateway.private[0].allocation_id == "eipalloc-11111111111111111"
    error_message = "Expected external EIP allocation IDs to be reused."
  }

  assert {
    condition     = length(aws_flow_log.public_subnet_flow_log) == 2 && length(aws_flow_log.private_subnet_flow_log) == 2
    error_message = "Expected flow logs for both public and private subnets."
  }
}

run "invalid_missing_cidr_block_fails_validation" {
  command = plan

  variables {
    type               = "public"
    availability_zones = ["us-east-1a"]
  }

  expect_failures = [
    var.cidr_block,
  ]
}

run "invalid_cidr_block_and_ipam_pool_conflict" {
  command = plan

  variables {
    type                = "public"
    availability_zones  = ["us-east-1a"]
    cidr_block          = "10.0.0.0/16"
    ipv4_ipam_pool_id   = "ipam-pool-0123456789abcdef0"
    ipv4_netmask_length = 24
  }

  expect_failures = [
    var.cidr_block,
  ]
}
