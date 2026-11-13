#Module      : LABEL
#Description : Terraform label module variables.
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `prod-subnet` or `subnet`)."
}

variable "repository" {
  type        = string
  default     = "https://github.com/clouddrove/terraform-aws-subnet"
  description = "Terraform current module repo"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^https://", var.repository))
    error_message = "The module-repo value must be a valid Git repo link."
  }
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "label_order" {
  type        = list(string)
  default     = ["name", "environment"]
  description = "Label order, e.g. `name`,`Environment`."
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)."
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `organization`, `environment`, `name` and `attributes`."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags applied to every resource created by this module (e.g. `{ Team = \"platform\" }`). Generated label tags take precedence for duplicate keys."
}

variable "extra_public_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags applied to public subnets only (e.g. `{ \"kubernetes.io/role/elb\" = \"1\" }`)."
}

variable "extra_private_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags applied to private subnets only (e.g. `{ \"kubernetes.io/role/internal-elb\" = \"1\" }`)."
}

variable "managedby" {
  type        = string
  default     = "hello@clouddrove.com"
  description = "ManagedBy, eg 'CloudDrove'."
}

#Module      : SUBNET
#Description : Terraform SUBNET module variables.
variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "List of Availability Zones (e.g. `[\"us-east-1a\", \"us-east-1b\", \"us-east-1c\"]`). One subnet of each requested kind is created per AZ."

  validation {
    condition     = length(var.availability_zones) == length(distinct(var.availability_zones))
    error_message = "availability_zones must not contain duplicates."
  }

  validation {
    condition     = !var.enable || !contains(["private", "public", "public-private"], var.type) || length(var.availability_zones) > 0
    error_message = "availability_zones must contain at least one AZ when enabled and type is set."
  }
}

variable "type" {
  type        = string
  default     = ""
  description = "Type of subnets to create (`private`, `public`, or `public-private`)."

  validation {
    condition     = contains(["", "private", "public", "public-private"], var.type)
    error_message = "The type must be `private`, `public`, or `public-private`."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the existing VPC in which the subnets are created (e.g. `vpc-0abc1234def567890`)."
}

variable "cidr_block" {
  type        = string
  default     = null
  description = "Base IPv4 CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`). Not needed when `ipv4_public_cidrs` / `ipv4_private_cidrs` are set."

  validation {
    condition     = var.cidr_block == null || can(cidrnetmask(var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR block (e.g. `10.0.0.0/16`)."
  }
}

variable "ipv6_cidr_block" {
  type        = string
  default     = null
  description = "IPv6 CIDR block of the VPC, divided into /64 subnet CIDRs when `enable_ipv6 = true` (e.g. `2a05:d018:832:ca00::/56`)."

  validation {
    condition     = var.ipv6_cidr_block == null || (can(cidrhost(var.ipv6_cidr_block, 0)) && can(regex(":", var.ipv6_cidr_block)) && try(tonumber(split("/", var.ipv6_cidr_block)[1]) <= 64, false))
    error_message = "ipv6_cidr_block must be a valid IPv6 CIDR with a prefix length of /64 or shorter (e.g. `2a05:d018:832:ca00::/56`)."
  }
}

variable "public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Existing public subnet IDs used to place NAT gateways when `type = \"private\"` (ignored when this module creates the public subnets)."
}

variable "igw_id" {
  type        = string
  default     = ""
  description = "Internet Gateway ID used as the default route of the public subnets (e.g. `igw-9c26a123`). Required when `type` is `public` or `public-private`."
}

variable "enable" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "enable_public_acl" {
  type        = bool
  default     = true
  description = "Set to false to skip creating the Network ACL (and its rules) for the public subnets."
}

variable "enable_private_acl" {
  type        = bool
  default     = true
  description = "Set to false to skip creating the Network ACL (and its rules) for the private subnets."
}

variable "nat_gateway_enabled" {
  type        = bool
  default     = false
  description = "Enable NAT Gateway creation for private subnets. Set single_nat_gateway = true to share one gateway across all private subnets."
}

variable "enable_flow_log" {
  type        = bool
  default     = false
  description = "Create a VPC Flow Log for every subnet created by this module. Requires `flow_log_destination_arn` (and `flow_log_iam_role_arn` for CloudWatch Logs)."
}

variable "map_public_ip_on_launch" {
  type        = bool
  default     = false
  description = "Specify true to indicate that instances launched into the public subnet should be assigned a public IP address."
}

#Module      : FLOW LOG
#Description : Terraform flow log module variables.
variable "flow_log_destination_arn" {
  type        = string
  default     = null
  description = "ARN of the CloudWatch Logs log group, S3 bucket or Firehose stream that receives the flow logs. Required when `enable_flow_log = true`."
}

variable "flow_log_destination_type" {
  type        = string
  default     = "cloud-watch-logs"
  description = "Type of flow log destination. Can be `s3`, `cloud-watch-logs` or `kinesis-data-firehose`."

  validation {
    condition     = contains(["s3", "cloud-watch-logs", "kinesis-data-firehose"], var.flow_log_destination_type)
    error_message = "flow_log_destination_type must be `s3`, `cloud-watch-logs` or `kinesis-data-firehose`."
  }
}

variable "flow_log_traffic_type" {
  type        = string
  default     = "ALL"
  description = "Type of traffic to capture. Valid values: ACCEPT,REJECT, ALL."

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be `ACCEPT`, `REJECT` or `ALL`."
  }
}

variable "flow_log_log_format" {
  type        = string
  default     = null
  description = "The fields to include in the flow log record, in the order in which they should appear"
}

variable "flow_log_iam_role_arn" {
  type        = string
  default     = null
  description = "The ARN for the IAM role that's used to post flow logs to a CloudWatch Logs log group. When flow_log_destination_arn is set to ARN of Cloudwatch Logs, this argument needs to be provided"
}

variable "flow_log_max_aggregation_interval" {
  type        = number
  default     = 600
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: `60` seconds or `600` seconds"

  validation {
    condition     = contains([60, 600], var.flow_log_max_aggregation_interval)
    error_message = "flow_log_max_aggregation_interval must be 60 or 600."
  }
}

variable "flow_log_file_format" {
  type        = string
  default     = null
  description = "(Optional) The format for the flow log. Valid values: `plain-text`, `parquet`"
}

variable "flow_log_hive_compatible_partitions" {
  type        = bool
  default     = false
  description = "(Optional) Indicates whether to use Hive-compatible prefixes for flow logs stored in Amazon S3"
}

variable "flow_log_per_hour_partition" {
  type        = bool
  default     = false
  description = "(Optional) Indicates whether to partition the flow log per hour. This reduces the cost and response time for queries"
}

variable "public_ipv6_cidrs" {
  type        = list(string)
  default     = []
  description = "Public Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`)."

  validation {
    condition     = alltrue([for c in var.public_ipv6_cidrs : can(cidrhost(c, 0)) && can(regex(":", c)) && try(tonumber(split("/", c)[1]) == 64, false)])
    error_message = "Every public_ipv6_cidrs entry must be a valid IPv6 /64 CIDR block."
  }
}

variable "private_ipv6_cidrs" {
  type        = list(string)
  default     = []
  description = "Private Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`)."

  validation {
    condition     = alltrue([for c in var.private_ipv6_cidrs : can(cidrhost(c, 0)) && can(regex(":", c)) && try(tonumber(split("/", c)[1]) == 64, false)])
    error_message = "Every private_ipv6_cidrs entry must be a valid IPv6 /64 CIDR block."
  }
}

variable "ipv4_public_cidrs" {
  type        = list(string)
  default     = []
  description = "Explicit IPv4 CIDRs for the public subnets, one per availability zone, in the same order. When empty, CIDRs are derived from `cidr_block`."

  validation {
    condition     = alltrue([for c in var.ipv4_public_cidrs : can(cidrnetmask(c))])
    error_message = "Every entry of ipv4_public_cidrs must be a valid IPv4 CIDR block."
  }
}
variable "ipv4_private_cidrs" {
  type        = list(string)
  default     = []
  description = "Explicit IPv4 CIDRs for the private subnets, one per availability zone, in the same order. When empty, CIDRs are derived from `cidr_block`."

  validation {
    condition     = alltrue([for c in var.ipv4_private_cidrs : can(cidrnetmask(c))])
    error_message = "Every entry of ipv4_private_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "single_nat_gateway" {
  type        = bool
  default     = false
  description = "When nat_gateway_enabled is true, create one NAT Gateway and route all private subnets through it."
}

variable "public_subnet_assign_ipv6_address_on_creation" {
  type        = bool
  default     = false
  description = "Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address."
}

variable "private_subnet_assign_ipv6_address_on_creation" {
  type        = bool
  default     = false
  description = "Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address."
}

variable "public_subnet_private_dns_hostname_type_on_launch" {
  type        = string
  default     = null
  description = "The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name`"
}

variable "private_subnet_private_dns_hostname_type_on_launch" {
  type        = string
  default     = null
  description = "The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: `ip-name`, `resource-name`"
}

variable "public_subnet_ipv6_native" {
  type        = bool
  default     = false
  description = "Create IPv6-only public subnets. Requires enable_ipv6 = true and no IPv4 CIDRs."
}

variable "private_subnet_ipv6_native" {
  type        = bool
  default     = false
  description = "Create IPv6-only private subnets. Requires enable_ipv6 = true and no IPv4 CIDRs."
}

variable "enable_ipv6" {
  type        = bool
  default     = false
  description = "Enable IPv6 on the subnets. The VPC must already have an IPv6 CIDR block; pass it via `ipv6_cidr_block`."
}

variable "public_subnet_enable_dns64" {
  type        = bool
  default     = false
  description = "Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `false`"
}

variable "private_subnet_enable_dns64" {
  type        = bool
  default     = false
  description = "Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true`"
}

variable "public_subnet_enable_resource_name_dns_a_record_on_launch" {
  type        = bool
  default     = false
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false`"
}

variable "private_subnet_enable_resource_name_dns_a_record_on_launch" {
  type        = bool
  default     = false
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: `false`"
}

variable "public_subnet_enable_resource_name_dns_aaaa_record_on_launch" {
  type        = bool
  default     = false
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true`"
}

variable "private_subnet_enable_resource_name_dns_aaaa_record_on_launch" {
  type        = bool
  default     = false
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `true`"
}

variable "public_inbound_acl_rules" {
  type = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
  description = "Public subnets inbound network ACLs"

  validation {
    condition = alltrue([
      for r in var.public_inbound_acl_rules :
      can(tonumber(r.rule_number)) && try(tonumber(r.rule_number) >= 1 && tonumber(r.rule_number) <= 32766, false) && contains(["allow", "deny"], try(r.rule_action, ""))
    ])
    error_message = "public_inbound_acl_rules: every rule needs a rule_number between 1 and 32766 and rule_action `allow` or `deny`."
  }
}

variable "public_outbound_acl_rules" {
  type = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
  description = "Public subnets outbound network ACLs"

  validation {
    condition = alltrue([
      for r in var.public_outbound_acl_rules :
      can(tonumber(r.rule_number)) && try(tonumber(r.rule_number) >= 1 && tonumber(r.rule_number) <= 32766, false) && contains(["allow", "deny"], try(r.rule_action, ""))
    ])
    error_message = "public_outbound_acl_rules: every rule needs a rule_number between 1 and 32766 and rule_action `allow` or `deny`."
  }
}

variable "private_inbound_acl_rules" {
  type = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
  description = "Private subnets inbound network ACLs"

  validation {
    condition = alltrue([
      for r in var.private_inbound_acl_rules :
      can(tonumber(r.rule_number)) && try(tonumber(r.rule_number) >= 1 && tonumber(r.rule_number) <= 32766, false) && contains(["allow", "deny"], try(r.rule_action, ""))
    ])
    error_message = "private_inbound_acl_rules: every rule needs a rule_number between 1 and 32766 and rule_action `allow` or `deny`."
  }
}

variable "private_outbound_acl_rules" {
  type = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
  description = "Private subnets outbound network ACLs"

  validation {
    condition = alltrue([
      for r in var.private_outbound_acl_rules :
      can(tonumber(r.rule_number)) && try(tonumber(r.rule_number) >= 1 && tonumber(r.rule_number) <= 32766, false) && contains(["allow", "deny"], try(r.rule_action, ""))
    ])
    error_message = "private_outbound_acl_rules: every rule needs a rule_number between 1 and 32766 and rule_action `allow` or `deny`."
  }
}

variable "nat_gateway_destination_cidr_block" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Used to pass a custom destination route for private NAT Gateway. If not specified, the default 0.0.0.0/0 is used as a destination route"
}

variable "public_rt_ipv4_destination_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "The destination ipv4 CIDR block."
}

variable "public_rt_ipv6_destination_cidr" {
  type        = string
  default     = "::/0"
  description = "The destination ipv6 CIDR block."
}

variable "nat_gateway_connectivity_type" {
  type        = string
  default     = "public"
  description = "NAT Gateway connectivity type. public (default) creates a standard NAT with EIP. private creates a private NAT (no EIP, routes between VPCs/on-prem). Valid values: public, private."
  validation {
    condition     = contains(["public", "private"], var.nat_gateway_connectivity_type)
    error_message = "nat_gateway_connectivity_type must be public or private."
  }
}

variable "additional_public_routes_for_all" {
  description = <<-EOT
    Routes added to EVERY public route table (all AZs get the same routes).
    Use this when you want uniform routing across all AZs.

    Example:
      additional_public_routes_for_all = [
        {
          destination_cidr_block = "10.100.0.0/16"
          gateway_id             = aws_vpn_gateway.this.id
        }
      ]
  EOT
  type        = list(map(string))
  default     = []
}

variable "additional_public_routes_per_subnet" {
  description = <<-EOT
    Routes added to specific AZ public route tables only.
    Key = AZ name, Value = list of routes for that AZ.
    AZs not listed here get no additional per-subnet routes.

    Example:
      additional_public_routes_per_subnet = {
        "eu-west-1a" = [
          {
            destination_cidr_block = "192.168.1.0/24"
            gateway_id             = aws_vpn_gateway.this.id
          }
        ]
        "eu-west-1b" = [
          {
            destination_cidr_block = "192.168.2.0/24"
            transit_gateway_id     = aws_ec2_transit_gateway.this.id
          }
        ]
      }
  EOT
  type        = map(list(map(string)))
  default     = {}
}

variable "additional_private_routes_for_all" {
  description = <<-EOT
    Routes added to EVERY private route table (all AZs get the same routes).
    Use this when you want uniform routing across all AZs.

    Example:
      additional_private_routes_for_all = [
        {
          destination_cidr_block = "10.100.0.0/16"
          gateway_id             = aws_vpn_gateway.this.id
        }
      ]
  EOT
  type        = list(map(string))
  default     = []
}

variable "additional_private_routes_per_subnet" {
  description = <<-EOT
    Routes added to specific AZ private route tables only.
    Key = AZ name, Value = list of routes for that AZ.
    AZs not listed here get no additional per-subnet routes.

    Example:
      additional_private_routes_per_subnet = {
        "eu-west-1a" = [
          {
            destination_cidr_block = "192.168.1.0/24"
            gateway_id             = aws_vpn_gateway.this.id
          }
        ]
      }
  EOT
  type        = map(list(map(string)))
  default     = {}
}
