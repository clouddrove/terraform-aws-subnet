output "public_subnet_cidrs" {
  value       = module.subnets.public_subnet_cidrs
  description = "The CIDR of the public subnets."
}

output "public_subnet_cidrs_ipv6" {
  value       = module.subnets.public_subnet_cidrs_ipv6
  description = "The IPv6 CIDR of the public subnets."
}

output "private_subnet_cidrs" {
  value       = module.subnets.private_subnet_cidrs
  description = "The CIDR of the private subnets."
}

output "private_subnet_cidrs_ipv6" {
  value       = module.subnets.private_subnet_cidrs_ipv6
  description = "The IPv6 CIDR of the private subnets."
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
  description = "The ID of the public subnet."
}

output "nat_gateway_private_ip" {
  value       = module.subnets.nat_gateway_private_ip
  description = "The private IPv4 address of the NAT Gateway."
}

output "public_route_tables_id" {
  value       = module.subnets.public_route_tables_id
  description = "The IDs of the public route tables. Use these to verify custom route entries in the AWS Console."
}

output "private_route_tables_id" {
  value       = module.subnets.private_route_tables_id
  description = "The IDs of the private route tables. Use these to verify custom route entries in the AWS Console."
}