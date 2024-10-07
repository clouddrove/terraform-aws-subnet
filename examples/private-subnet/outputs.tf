output "private_subnet_cidrs" {
  value       = module.private-subnets.private_subnet_cidrs
  description = "The ID of the subnet."
}

output "private_tags" {
  value       = module.private-subnets.private_tags
  description = "A mapping of tags to assign to the resource."
}
output "nat_gateway_private_ip" {
  value       = module.private-subnets.nat_gateway_private_ip
  description = "The private IPv4 address to assign to the NAT Gateway. If you don't provide an address, a private IPv4 address will be automatically assigned."
}
