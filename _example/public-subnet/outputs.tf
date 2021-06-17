output "public_subnet_cidrs" {
  value       = module.subnets.public_subnet_cidrs
  description = "The CIDR of the subnet."
}

output "public_subnet_cidrs_ipv6" {
  value       = module.subnets.public_subnet_cidrs_ipv6
  description = "The CIDR of the subnet."
}

output "public_tags" {
  value       = module.subnets.public_tags
  description = "A mapping of tags to assign to the resource."
}
