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
  type        = list(any)
  default     = ["name", "environment"]
  description = "Label order, e.g. `name`,`Environment`."
}

variable "attributes" {
  type        = list(any)
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
  description = "Common tags applied to all resources created by this module."
}

variable "extra_public_tags" {
  type        = map(any)
  default     = {}
  description = "Additional public subnet tags."
}

variable "extra_private_tags" {
  type        = map(any)
  default     = {}
  description = "Additional private subnet tags."
}

variable "public_subnet_tags_per_az" {
  type        = map(map(string))
  default     = {}
  description = "Additional tags to merge onto public subnets keyed by Availability Zone name or AZ ID."
}

variable "private_subnet_tags_per_az" {
  type        = map(map(string))
  default     = {}
  description = "Additional tags to merge onto private subnets keyed by Availability Zone name or AZ ID."
}

variable "public_route_table_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for public route tables."
}

variable "private_route_table_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for private route tables."
}

variable "public_acl_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for the public network ACL."
}

variable "private_acl_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for the private network ACL."
}

variable "nat_gateway_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for NAT Gateways."
}

variable "nat_eip_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for NAT Gateway Elastic IPs."
}

variable "flow_log_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for subnet flow logs."
}

variable "managedby" {
  type        = string
  default     = "hello@clouddrove.com"
  description = "ManagedBy, eg 'CloudDrove'."
}

#Module      : SUBNET
#Description : Terraform SUBNET module variables.
variable "region" {
  type        = string
  default     = null
  description = "AWS region where resources will be managed. Defaults to the region configured in the provider."
}

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)."

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zone_ids) == 0
    error_message = "Set either availability_zones or availability_zone_ids, not both."
  }
}

variable "availability_zone_ids" {
  type        = list(string)
  default     = []
  description = "List of Availability Zone IDs (e.g. `use1-az1`, `use1-az2`). Use this instead of availability_zones when consistent AZ mapping across AWS accounts is needed."
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
  description = "VPC ID."
  sensitive   = true
}

variable "cidr_block" {
  type        = string
  default     = null
  description = "Base IPv4 CIDR block divided into subnet CIDR blocks (e.g. `10.0.0.0/16`). Not used when IPv4 IPAM allocation is enabled or a subnet is IPv6-only."

  validation {
    condition = (var.ipv4_ipam_pool_id == null || var.cidr_block == null) && (
      !var.enable || var.ipv4_ipam_pool_id != null || (
        (!(var.type == "public" || var.type == "public-private") || var.public_subnet_ipv6_native || length(var.ipv4_public_cidrs) > 0 || (var.cidr_block != null && var.cidr_block != "")) &&
        (!(var.type == "private" || var.type == "public-private") || var.private_subnet_ipv6_native || length(var.ipv4_private_cidrs) > 0 || (var.cidr_block != null && var.cidr_block != ""))
      )
    )
    error_message = "Provide cidr_block, ipv4_ipam_pool_id, or explicit IPv4 subnet CIDRs for IPv4-capable subnets, and do not set both cidr_block and ipv4_ipam_pool_id."
  }
}

variable "ipv4_ipam_pool_id" {
  type        = string
  default     = null
  description = "Optional IPv4 IPAM pool ID used to allocate subnet CIDRs. When set, ipv4_netmask_length is required and cidr_block and explicit IPv4 subnet CIDR lists must be unset."

  validation {
    condition = var.ipv4_ipam_pool_id == null || (
      length(var.ipv4_public_cidrs) == 0 &&
      length(var.ipv4_private_cidrs) == 0 &&
      !(
        (var.type == "public" && var.public_subnet_ipv6_native) ||
        (var.type == "private" && var.private_subnet_ipv6_native) ||
        (var.type == "public-private" && var.public_subnet_ipv6_native && var.private_subnet_ipv6_native)
      )
    )
    error_message = "When ipv4_ipam_pool_id is set, do not set explicit IPv4 subnet CIDRs, and ensure at least one subnet type is not IPv6-only."
  }
}

variable "ipv4_netmask_length" {
  type        = number
  default     = null
  description = "IPv4 prefix length to request from ipv4_ipam_pool_id."

  validation {
    condition     = var.ipv4_ipam_pool_id == null ? var.ipv4_netmask_length == null : var.ipv4_netmask_length != null && var.ipv4_netmask_length >= 16 && var.ipv4_netmask_length <= 28
    error_message = "Set ipv4_netmask_length from 16 to 28 when ipv4_ipam_pool_id is set, and leave it unset otherwise."
  }
}

variable "ipv6_cidr_block" {
  type        = string
  default     = null
  description = "Base IPv6 CIDR block divided into /64 subnet CIDRs. Not used when IPv6 IPAM allocation is enabled."
}

variable "ipv6_ipam_pool_id" {
  type        = string
  default     = null
  description = "Optional IPv6 IPAM pool ID used to allocate subnet CIDRs when enable_ipv6 is true. When set, ipv6_netmask_length is required and ipv6_cidr_block and explicit IPv6 subnet CIDR lists must be unset."

  validation {
    condition = var.ipv6_ipam_pool_id == null || (
      var.ipv6_cidr_block == null &&
      length(var.public_ipv6_cidrs) == 0 &&
      length(var.private_ipv6_cidrs) == 0
    )
    error_message = "When ipv6_ipam_pool_id is set, ipv6_cidr_block and explicit IPv6 subnet CIDRs must be unset."
  }
}

variable "ipv6_netmask_length" {
  type        = number
  default     = null
  description = "IPv6 prefix length to request from ipv6_ipam_pool_id (44–64 in increments of 4; must be 64 for IPv6-only subnets)."

  validation {
    condition     = var.ipv6_ipam_pool_id == null ? var.ipv6_netmask_length == null : var.ipv6_netmask_length != null && var.ipv6_netmask_length >= 44 && var.ipv6_netmask_length <= 64 && (var.ipv6_netmask_length - 44) % 4 == 0 && (!(var.public_subnet_ipv6_native || var.private_subnet_ipv6_native) || var.ipv6_netmask_length == 64)
    error_message = "Set ipv6_netmask_length from 44 to 64 in increments of 4 (and 64 for IPv6-only subnets) when ipv6_ipam_pool_id is set, and leave it unset otherwise."
  }
}

variable "public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "A list of public subnet ids."
  sensitive   = true

  validation {
    condition     = !var.enable || !var.nat_gateway_enabled || var.nat_gateway_availability_mode == "regional" || var.type != "private" || length(var.public_subnet_ids) > 0
    error_message = "When creating zonal NAT Gateways for private-only subnets, provide at least one public_subnet_id."
  }

}

variable "igw_id" {
  type        = string
  default     = ""
  description = "Internet Gateway ID that is used as a default route when creating public subnets (e.g. `igw-9c26a123`)."
  sensitive   = true
}

variable "enable_eigw" {
  type        = bool
  default     = false
  description = "Create a private IPv6 default route (`::/0`) targeting `eigw_id` in private route tables. Requires `enable_ipv6 = true` and `eigw_id`."
}

variable "eigw_id" {
  type        = string
  default     = null
  description = "Egress-Only Internet Gateway ID used for private subnet IPv6 default routes when enable_ipv6 and enable_eigw are true (e.g. `eigw-9c26a123`)."
  sensitive   = true
}

variable "enable" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "enable_public_acl" {
  type        = bool
  default     = true
  description = "Set to false to skip creating the public network ACL and its rules."
}

variable "enable_private_acl" {
  type        = bool
  default     = true
  description = "Set to false to skip creating the private network ACL and its rules."
}

variable "nat_gateway_enabled" {
  type        = bool
  default     = false
  description = "Flag to enable or disable NAT Gateway creation for private subnets. For zonal NAT Gateways, a public subnet or public_subnet_ids must be available for placement."

  validation {
    condition     = !var.enable || !var.nat_gateway_enabled || ((var.type == "private" || var.type == "public-private") && (var.nat_gateway_availability_mode == "regional" || !(var.type == "public-private" && var.public_subnet_ipv6_native)))
    error_message = "NAT Gateways require private subnets, and zonal NAT Gateways require an IPv4-capable public subnet for placement."
  }
}

variable "enable_flow_log" {
  type        = bool
  default     = false
  description = "Enable subnet_flow_log logs."
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
  description = "ARN of resource in which flow log will be sent."
  sensitive   = true
}

variable "flow_log_destination_type" {
  type        = string
  default     = "cloud-watch-logs"
  description = "Type of flow log destination. Can be `cloud-watch-logs`, `s3`, or `kinesis-data-firehose`."

  validation {
    condition     = contains(["cloud-watch-logs", "s3", "kinesis-data-firehose"], var.flow_log_destination_type)
    error_message = "flow_log_destination_type must be `cloud-watch-logs`, `s3`, or `kinesis-data-firehose`."
  }
}

variable "flow_log_traffic_type" {
  type        = string
  default     = "ALL"
  description = "Type of traffic to capture. Valid values: ACCEPT,REJECT, ALL."
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

variable "flow_log_deliver_cross_account_role" {
  type        = string
  default     = null
  description = "(Optional) ARN of the IAM role that allows Amazon EC2 to publish flow logs across accounts."
}

variable "flow_log_max_aggregation_interval" {
  type        = number
  default     = 600
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: `60` seconds or `600` seconds"
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
  type        = list(any)
  default     = []
  description = "Public Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`)."
}

variable "private_ipv6_cidrs" {
  type        = list(any)
  default     = []
  description = "Private Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`)."
}

variable "ipv4_public_cidrs" {
  type        = list(any)
  default     = []
  description = "Subnet CIDR blocks (e.g. `10.0.0.0/16`)."
}
variable "ipv4_private_cidrs" {
  type        = list(any)
  default     = []
  description = "Subnet CIDR blocks (e.g. `10.0.0.0/16`)."
}

variable "single_nat_gateway" {
  type        = bool
  default     = false
  description = "Create one NAT Gateway and share one private route table across AZs when nat_gateway_enabled is true."
}

variable "reuse_nat_ips" {
  type        = bool
  default     = false
  description = "Set to true to reuse existing Elastic IP allocation IDs supplied via external_nat_ip_ids instead of creating new EIPs for zonal public NAT Gateways."
}

variable "external_nat_ip_ids" {
  type        = list(string)
  default     = []
  description = "List of existing Elastic IP allocation IDs to attach to zonal public NAT Gateways when reuse_nat_ips is true."

  validation {
    condition = !var.enable || !var.nat_gateway_enabled || !var.reuse_nat_ips || var.nat_gateway_availability_mode == "regional" || var.nat_gateway_connectivity_type != "public" || (
      length(var.external_nat_ip_ids) >= (var.single_nat_gateway ? 1 : max(length(var.availability_zones), length(var.availability_zone_ids)))
    )
    error_message = "When reuse_nat_ips is true for zonal public NAT Gateways, external_nat_ip_ids must contain at least one EIP allocation ID per NAT Gateway."
  }
}

variable "nat_gateway_availability_mode" {
  type        = string
  default     = "zonal"
  description = "NAT Gateway availability mode (`zonal` or `regional`). `regional` creates a multi-AZ regional NAT Gateway attached directly to the VPC."

  validation {
    condition     = contains(["zonal", "regional"], var.nat_gateway_availability_mode)
    error_message = "nat_gateway_availability_mode must be `zonal` or `regional`."
  }
}

variable "regional_nat_gateway_address" {
  type = list(object({
    allocation_ids       = optional(list(string))
    availability_zone    = optional(string)
    availability_zone_id = optional(string)
  }))
  default     = []
  description = "Optional manual AZ-to-EIP mappings for a regional NAT Gateway (`availability_mode = regional`). Leave empty for AWS auto mode."
}

variable "nat_gateway_secondary_private_ip_address_count" {
  type        = number
  default     = null
  description = "Number of secondary private IPv4 addresses to assign to each zonal NAT Gateway."
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
  description = "Indicates whether to create an IPv6-only public subnet. Default: `false`"

  validation {
    condition     = !var.public_subnet_ipv6_native || (var.enable_ipv6 && length(var.ipv4_public_cidrs) == 0 && (var.ipv6_cidr_block != null || var.ipv6_ipam_pool_id != null || length(var.public_ipv6_cidrs) > 0))
    error_message = "IPv6-only public subnets require enable_ipv6 = true, an IPv6 CIDR source, and no explicit ipv4_public_cidrs."
  }
}

variable "private_subnet_ipv6_native" {
  type        = bool
  default     = false
  description = "Indicates whether to create an IPv6-only private subnet. Default: `false`"

  validation {
    condition     = !var.private_subnet_ipv6_native || (var.enable_ipv6 && length(var.ipv4_private_cidrs) == 0 && (var.ipv6_cidr_block != null || var.ipv6_ipam_pool_id != null || length(var.private_ipv6_cidrs) > 0))
    error_message = "IPv6-only private subnets require enable_ipv6 = true, an IPv6 CIDR source, and no explicit ipv4_private_cidrs."
  }
}

variable "enable_ipv6" {
  type        = bool
  default     = false
  description = "Enable IPv6 CIDR assignment and subnet IPv6 settings. The VPC must already have an IPv6 CIDR block or an IPv6 IPAM pool must be configured."

  validation {
    condition = !var.enable || !var.enable_ipv6 || var.ipv6_ipam_pool_id != null || (
      ((var.type != "public" && var.type != "public-private") || var.ipv6_cidr_block != null || length(var.public_ipv6_cidrs) > 0) &&
      ((var.type != "private" && var.type != "public-private") || var.ipv6_cidr_block != null || length(var.private_ipv6_cidrs) > 0)
    )
    error_message = "When IPv6 is enabled, provide ipv6_cidr_block or an IPv6 CIDR list for every subnet type being created."
  }
}

variable "public_subnet_enable_dns64" {
  type        = bool
  default     = false
  description = "Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `false`"
}

variable "private_subnet_enable_dns64" {
  type        = bool
  default     = false
  description = "Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `false`"
}

variable "enable_nat64" {
  type        = bool
  default     = false
  description = "Create a NAT64 IPv6 route (`64:ff9b::/96` by default) in private route tables targeting the NAT Gateway. Requires enable_ipv6 = true and nat_gateway_enabled = true."

  validation {
    condition     = !var.enable || !var.enable_nat64 || (var.enable_ipv6 && var.nat_gateway_enabled)
    error_message = "enable_nat64 requires enable_ipv6 = true and nat_gateway_enabled = true."
  }
}

variable "nat64_destination_ipv6_cidr_block" {
  type        = string
  default     = "64:ff9b::/96"
  description = "Destination IPv6 CIDR block for the NAT64 route in private route tables."
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
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `false`"
}

variable "private_subnet_enable_resource_name_dns_aaaa_record_on_launch" {
  type        = bool
  default     = false
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: `false`"
}

variable "public_subnet_outpost_arn" {
  type        = string
  default     = null
  description = "ARN of the AWS Outpost where public subnets should be created."
}

variable "private_subnet_outpost_arn" {
  type        = string
  default     = null
  description = "ARN of the AWS Outpost where private subnets should be created."
}

variable "public_subnet_customer_owned_ipv4_pool" {
  type        = string
  default     = null
  description = "Customer-owned IPv4 address pool (CoIP pool) ID for Outpost public subnets. Requires public_subnet_outpost_arn."

  validation {
    condition     = var.public_subnet_customer_owned_ipv4_pool == null || var.public_subnet_outpost_arn != null
    error_message = "public_subnet_customer_owned_ipv4_pool requires public_subnet_outpost_arn to be set."
  }
}

variable "private_subnet_customer_owned_ipv4_pool" {
  type        = string
  default     = null
  description = "Customer-owned IPv4 address pool (CoIP pool) ID for Outpost private subnets. Requires private_subnet_outpost_arn."

  validation {
    condition     = var.private_subnet_customer_owned_ipv4_pool == null || var.private_subnet_outpost_arn != null
    error_message = "private_subnet_customer_owned_ipv4_pool requires private_subnet_outpost_arn to be set."
  }
}

variable "public_subnet_map_customer_owned_ip_on_launch" {
  type        = bool
  default     = false
  description = "Assign a customer-owned IPv4 address on launch for Outpost public subnets. Requires public_subnet_outpost_arn and public_subnet_customer_owned_ipv4_pool."

  validation {
    condition     = !var.public_subnet_map_customer_owned_ip_on_launch || (var.public_subnet_outpost_arn != null && var.public_subnet_customer_owned_ipv4_pool != null)
    error_message = "public_subnet_map_customer_owned_ip_on_launch requires public_subnet_outpost_arn and public_subnet_customer_owned_ipv4_pool."
  }
}

variable "private_subnet_map_customer_owned_ip_on_launch" {
  type        = bool
  default     = false
  description = "Assign a customer-owned IPv4 address on launch for Outpost private subnets. Requires private_subnet_outpost_arn and private_subnet_customer_owned_ipv4_pool."

  validation {
    condition     = !var.private_subnet_map_customer_owned_ip_on_launch || (var.private_subnet_outpost_arn != null && var.private_subnet_customer_owned_ipv4_pool != null)
    error_message = "private_subnet_map_customer_owned_ip_on_launch requires private_subnet_outpost_arn and private_subnet_customer_owned_ipv4_pool."
  }
}

variable "public_subnet_enable_lni_at_device_index" {
  type        = number
  default     = null
  description = "Device index (e.g. `1` for eth1) for Local Network Interfaces (LNIs) in Outpost public subnets."

  validation {
    condition     = var.public_subnet_enable_lni_at_device_index == null ? true : var.public_subnet_enable_lni_at_device_index >= 1
    error_message = "public_subnet_enable_lni_at_device_index must be >= 1 because a local network interface cannot be eth0."
  }
}

variable "private_subnet_enable_lni_at_device_index" {
  type        = number
  default     = null
  description = "Device index (e.g. `1` for eth1) for Local Network Interfaces (LNIs) in Outpost private subnets."

  validation {
    condition     = var.private_subnet_enable_lni_at_device_index == null ? true : var.private_subnet_enable_lni_at_device_index >= 1
    error_message = "private_subnet_enable_lni_at_device_index must be >= 1 because a local network interface cannot be eth0."
  }
}

variable "public_propagating_vgws" {
  type        = list(string)
  default     = []
  description = "List of Virtual Private Gateway IDs to propagate routes into public route tables."
}

variable "private_propagating_vgws" {
  type        = list(string)
  default     = []
  description = "List of Virtual Private Gateway IDs to propagate routes into private route tables."
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

variable "private_rt_ipv6_destination_cidr" {
  type        = string
  default     = "::/0"
  description = "The destination IPv6 CIDR block for private route table egress-only internet gateway routes."
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
    Key = AZ name or AZ ID, Value = list of routes for that AZ.
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
    Routes added to every private route table. With a single NAT Gateway, the route is added once to the shared private route table.
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
    Key = AZ name or AZ ID, Value = list of routes for that AZ.
    AZs not listed here get no additional per-subnet routes.
    Do not use this with single_nat_gateway=true and nat_gateway_enabled=true because all private subnets share one route table.

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

  validation {
    condition     = !var.enable || !var.single_nat_gateway || !var.nat_gateway_enabled || length(var.additional_private_routes_per_subnet) == 0
    error_message = "additional_private_routes_per_subnet cannot be combined with single_nat_gateway when NAT gateways are enabled because all private subnets share one route table."
  }
}
