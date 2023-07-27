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
  type        = map(any)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
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
  description = "List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)."
}

variable "type" {
  type        = string
  default     = ""
  description = "Type of subnets to create (`private` or `public`)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
  sensitive   = true
}

variable "cidr_block" {
  type        = string
  default     = null
  description = "Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)."
}

variable "ipv6_cidr_block" {
  type        = string
  default     = null
  description = "Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)."
}

variable "public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "A list of public subnet ids."
  sensitive   = true

}

variable "igw_id" {
  type        = string
  default     = ""
  description = "Internet Gateway ID that is used as a default route when creating public subnets (e.g. `igw-9c26a123`)."
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
  description = "Set to false to prevent the module from creating any resources."
}

variable "enable_private_acl" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "nat_gateway_enabled" {
  type        = bool
  default     = false
  description = "Flag to enable/disable NAT Gateways creation in public subnets."
}

variable "enable_flow_log" {
  type        = bool
  default     = false
  description = "Enable subnet_flow_log logs."
}

variable "map_public_ip_on_launch" {
  type        = bool
  default     = true
  description = "Specify true to indicate that instances launched into the public subnet should be assigned a public IP address."
}

variable "map_private_ip_on_launch" {
  type        = bool
  default     = true
  description = "Specify true to indicate that instances launched into the private subnet should be assigned a public IP address."
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
  description = "Type of flow log destination. Can be s3 or cloud-watch-logs"
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
  description = "Enable for only single NAT Gateway in one Availability Zone"
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
}

variable "private_subnet_ipv6_native" {
  type        = bool
  default     = false
  description = "Indicates whether to create an IPv6-only private subnet. Default: `false`"
}

variable "enable_ipv6" {
  type        = bool
  default     = false
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block"
}

variable "public_subnet_enable_dns64" {
  type        = bool
  default     = false
  description = "Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: `true`"
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
