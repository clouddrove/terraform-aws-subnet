#Module      : SUBNET
#Description : Terraform module to create public, private and public-private subnet with
#              network acl, route table, Elastic IP, nat gateway, flow log.
output "public_subnet_id" {
  value       = aws_subnet.public[*].id
  description = "The ID of the subnet."
}

output "public_subnet_cidrs" {
  value       = aws_subnet.public[*].cidr_block
  description = "CIDR blocks of the created public subnets."
}

output "public_subnet_cidrs_ipv6" {
  value       = aws_subnet.public[*].ipv6_cidr_block
  description = "CIDR blocks of the created public subnets."
}

output "private_subnet_id" {
  value       = aws_subnet.private[*].id
  description = "The ID of the private subnet."
}

output "private_subnet_cidrs" {
  value       = aws_subnet.private[*].cidr_block
  description = "CIDR blocks of the created private subnets."
}

output "private_subnet_cidrs_ipv6" {
  value       = aws_subnet.private[*].ipv6_cidr_block
  description = "CIDR blocks of the created private subnets."
}

output "public_route_tables_id" {
  value       = aws_route_table.public[*].id
  description = "The ID of the routing table."
}

output "private_route_tables_id" {
  value       = aws_route_table.private[*].id
  description = "The ID of the routing table."
}

output "private_tags" {
  value       = module.private-labels.tags
  description = "A mapping of private tags to assign to the resource."
}

output "public_tags" {
  value       = module.public-labels.tags
  description = "A mapping of public tags to assign to the resource."
}

output "public_acl" {
  value       = join("", aws_network_acl.public[*].id)
  description = "The ID of the network ACL."
}

output "private_acl" {
  value       = join("", aws_network_acl.private[*].id)
  description = "The ID of the network ACL."
}

output "nat_gateway_private_ip" {
  value       = aws_nat_gateway.private[*].private_ip
  description = "The private IPv4 address to assign to the NAT Gateway. If you don't provide an address, a private IPv4 address will be automatically assigned."
}
