# Plan-time tests using a mocked AWS provider (no credentials or network needed).
# Run with: terraform init -backend=false && terraform test

mock_provider "aws" {}

variables {
  name               = "app"
  environment        = "test"
  vpc_id             = "vpc-0123456789abcdef0"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["eu-west-1a", "eu-west-1b"]
  igw_id             = "igw-0123456789abcdef0"
}

run "public_private_creates_both_tiers" {
  command = plan

  variables {
    type = "public-private"
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected one public and one private subnet per AZ."
  }
}

run "single_nat_gateway_uses_one_nat_and_one_private_route_table" {
  command = plan

  variables {
    type               = "public-private"
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.private) == 1 && length(aws_route_table.private) == 1
    error_message = "single_nat_gateway must create exactly one NAT gateway and one private route table."
  }
}

run "public_only_creates_no_private_or_nat" {
  command = plan

  variables {
    type = "public"
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 0 && length(aws_nat_gateway.private) == 0
    error_message = "type = public must not create private subnets or NAT gateways."
  }
}

run "disabled_module_creates_nothing" {
  command = plan

  variables {
    enable = false
    type   = "public-private"
  }

  assert {
    condition     = length(aws_subnet.public) == 0 && length(aws_subnet.private) == 0
    error_message = "enable = false must create no resources."
  }
}

run "invalid_type_is_rejected" {
  command = plan

  variables {
    type = "bogus"
  }

  expect_failures = [var.type]
}

run "single_nat_does_not_duplicate_additional_private_routes" {
  command = plan

  variables {
    type               = "public-private"
    single_nat_gateway = true
    additional_private_routes_for_all = [
      {
        destination_cidr_block = "10.100.0.0/16"
        gateway_id             = "vgw-0123456789abcdef0"
      },
    ]
  }

  assert {
    condition     = length(aws_route.private_additional) == 1
    error_message = "With one shared private route table the same destination must be created once, not once per AZ."
  }
}

run "per_az_nat_keeps_one_additional_private_route_per_az" {
  command = plan

  variables {
    type = "public-private"
    additional_private_routes_for_all = [
      {
        destination_cidr_block = "10.100.0.0/16"
        gateway_id             = "vgw-0123456789abcdef0"
      },
    ]
  }

  assert {
    condition     = length(aws_route.private_additional) == 2
    error_message = "Each AZ has its own private route table, so each needs its own additional route."
  }
}
