#Module      : LABEL
#Description : Terraform label module variables.
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "application" {
  type        = string
  default     = ""
  description = "Application (e.g. `cd` or `clouddrove`)."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "label_order" {
  type        = list
  default     = []
  description = "Label order, e.g. `name`,`application`."
}

variable "attributes" {
  type        = list
  default     = []
  description = "Additional attributes (e.g. `1`)."
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `organization`, `environment`, `name` and `attributes`."
}

variable "tags" {
  type        = map
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}

variable "managedby" {
  type        = string
  default     = "anmol@clouddrove.com"
  description = "ManagedBy, eg 'CloudDrove' or 'AnmolNagpal'."
}

#Module      : SUBNET
#Description : Terraform SUBNET module variables.
variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)."
}

variable "max_subnets" {
  type        = number
  default     = 6
  description = "Maximum number of subnets that can be created. The variable is used for CIDR blocks calculation."
}

variable "type" {
  type        = string
  default     = ""
  description = "Type of subnets to create (`private` or `public`)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "cidr_block" {
  type        = string
  description = "Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)."
}

variable "ipv6_cidrs" {
  type        = list
  default     = []
  description = "Subnet CIDR blocks (e.g. `2a05:d018:832:ca02::/64`)."
}

variable "ipv4_cidrs" {
  type        = list
  default     = []
  description = "Subnet CIDR blocks (e.g. `10.0.0.0/16`)."
}

variable "ipv6_cidr_block" {
  type        = string
  description = "Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)."
}

variable "public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "A list of public subnet ids."
}

variable "igw_id" {
  type        = string
  default     = ""
  description = "Internet Gateway ID that is used as a default route when creating public subnets (e.g. `igw-9c26a123`)."
}

variable "az_ngw_ids" {
  type        = map(string)
  default     = {}
  description = "Only for private subnets. Map of AZ names to NAT Gateway IDs that are used as default routes when creating private subnets."
}

variable "public_network_acl_id" {
  type        = string
  default     = ""
  description = "Network ACL ID that is added to the public subnets. If empty, a new ACL will be created."
}

variable "private_network_acl_id" {
  type        = string
  default     = ""
  description = "Network ACL ID that is added to the private subnets. If empty, a new ACL will be created."
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "enable_acl" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "nat_gateway_enabled" {
  type        = bool
  default     = false
  description = "Flag to enable/disable NAT Gateways creation in public subnets."
}

variable "az_ngw_count" {
  type        = number
  default     = 0
  description = "Count of items in the `az_ngw_ids` map. Needs to be explicitly provided since Terraform currently can't use dynamic count on computed resources from different modules. https://github.com/hashicorp/terraform/issues/10857."
}

variable "enable_flow_log" {
  type        = bool
  default     = false
  description = "Enable subnet_flow_log logs."
}

variable "map_public_ip_on_launch" {
  type        = bool
  default     = true
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address."
}

#Module      : FLOW LOG
#Description : Terraform flow log module variables.
variable "s3_bucket_arn" {
  type        = string
  default     = ""
  description = "S3 ARN for vpc logs."
}

variable "traffic_type" {
  type        = string
  default     = "ALL"
  description = "Type of traffic to capture. Valid values: ACCEPT,REJECT, ALL."
}