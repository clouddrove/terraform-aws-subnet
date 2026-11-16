#Module      : SUBNET
#Description : Terraform module to create public, private and public-private subnet with
#              network acl, route table, Elastic IP, nat gateway, flow log.
output "public_subnet_id" {
  value       = aws_subnet.public[*].id
  description = "IDs of the created public subnets."
}

output "public_subnet_cidrs" {
  value       = aws_subnet.public[*].cidr_block
  description = "CIDR blocks of the created public subnets."
}

output "public_subnet_cidrs_ipv6" {
  value       = aws_subnet.public[*].ipv6_cidr_block
  description = "IPv6 CIDR blocks of the created public subnets."
}

output "private_subnet_id" {
  value       = aws_subnet.private[*].id
  description = "IDs of the created private subnets."
}

output "private_subnet_cidrs" {
  value       = aws_subnet.private[*].cidr_block
  description = "CIDR blocks of the created private subnets."
}

output "private_subnet_cidrs_ipv6" {
  value       = aws_subnet.private[*].ipv6_cidr_block
  description = "IPv6 CIDR blocks of the created private subnets."
}

output "public_route_tables_id" {
  value       = aws_route_table.public[*].id
  description = "IDs of the public route tables (one per AZ)."
}

output "private_route_tables_id" {
  value       = aws_route_table.private[*].id
  description = "IDs of the private route tables (one per AZ, or a single one when `single_nat_gateway = true`)."
}

output "private_tags" {
  value       = local.private_tags
  description = "A mapping of private tags to assign to the resource."
}

output "public_tags" {
  value       = local.public_tags
  description = "A mapping of public tags to assign to the resource."
}

output "public_acl" {
  value       = join("", aws_network_acl.public[*].id)
  description = "ID of the public subnets Network ACL (empty string when not created)."
}

output "private_acl" {
  value       = join("", aws_network_acl.private[*].id)
  description = "ID of the private subnets Network ACL (empty string when not created)."
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

output "public_subnet_arns" {
  value       = aws_subnet.public[*].arn
  description = "ARNs of the created public subnets, in the same order as public_subnet_id."
}

output "private_subnet_arns" {
  value       = aws_subnet.private[*].arn
  description = "ARNs of the created private subnets, in the same order as private_subnet_id."
}

output "public_subnet_ids_by_az" {
  value       = { for s in aws_subnet.public : s.availability_zone => s.id }
  description = "Map of availability zone => public subnet ID."
}

output "private_subnet_ids_by_az" {
  value       = { for s in aws_subnet.private : s.availability_zone => s.id }
  description = "Map of availability zone => private subnet ID."
}

output "nat_gateway_eip_allocation_ids" {
  value       = aws_eip.private[*].id
  description = "Allocation IDs of the Elastic IPs attached to the NAT Gateways (empty for private NAT gateways)."
}

output "public_flow_log_ids" {
  value       = aws_flow_log.public_subnet_flow_log[*].id
  description = "IDs of the flow logs created for the public subnets."
}

output "private_flow_log_ids" {
  value       = aws_flow_log.private_subnet_flow_log[*].id
  description = "IDs of the flow logs created for the private subnets."
}
