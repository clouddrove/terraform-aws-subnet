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
  description = "Private IPv4 address of each NAT Gateway."
}

output "nat_gateway_public_ip" {
  value       = aws_eip.private[*].public_ip
  description = "Public IPv4 address of each NAT Gateway EIP. Whitelist these in external firewalls."
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.private[*].id
  description = "IDs of created NAT Gateways."
}

output "public_subnet_azs" {
  value       = aws_subnet.public[*].availability_zone
  description = "Availability zones of created public subnets, in the same order as public_subnet_id."
}

output "private_subnet_azs" {
  value       = aws_subnet.private[*].availability_zone
  description = "Availability zones of created private subnets, in the same order as private_subnet_id."
}
