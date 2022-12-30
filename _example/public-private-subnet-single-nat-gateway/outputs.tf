output "public_subnet_cidrs" {
  value       = module.subnets.public_subnet_cidrs
  description = "The CIDR of the subnet."
}

output "public_subnet_cidrs_ipv6" {
  value       = module.subnets.public_subnet_cidrs_ipv6
  description = "The CIDR of the subnet."
}

output "private_subnet_cidrs" {
  value       = module.subnets.private_subnet_cidrs
  description = "The CIDR of the subnet."
}

output "private_subnet_cidrs_ipv6" {
  value       = module.subnets.private_subnet_cidrs_ipv6
  description = "The CIDR of the subnet."
}

output "private_tags" {
  value       = module.subnets.private_tags
  description = "A mapping of tags to assign to the resource."
}

output "public_tags" {
  value       = module.subnets.public_tags
  description = "A mapping of tags to assign to the resource."
}

output "public_subnet_id" {
  value       = module.subnets.private_subnet_id
  description = "The ID of the public subnet"
}