# output "check-webserver" {
#   value = module.web_server_1.public_ip
# }
#
# output "alb_dns" {
#   value = module.alb.alb_dns_name
# }



output "vpc_cidr" {
  value       = module.this.vpc_cidr
  description = "VPC CIDR block"
}

output "internet_gateway_id" {
  value       = module.this.internet_gateway_id
  description = "Internet Gateway ID"
}

# Public subnets (map keyed by AZ)
output "public_subnet_ids" {
  value       =  module.this.public_subnet_ids
  description = "Public subnet IDs keyed by AZ"
}

output "public_subnet_cidrs" {
  value       =  module.this.public_subnet_cidrs
  description = "Public subnet CIDRs keyed by AZ"
}

output "public_route_table_id" {
  value       = module.this.public_route_table_id
  description = "Public route table ID"
}

# Private subnets (map keyed by AZ)
output "private_subnet_ids" {
  value       = module.this.private_subnet_ids
  description = "Private subnet IDs keyed by AZ"
}

output "private_subnet_cidrs" {
  value       = module.this.private_subnet_cidrs
  description = "Private subnet CIDRs keyed by AZ"
}

# NAT resources (maps keyed by the AZ key used for public subnets)
output "nat_eip_allocation_ids" {
  value       = module.this.nat_eip_allocation_ids
  description = "NAT EIP allocation resource IDs keyed by AZ"
}

output "nat_eip_public_ips" {
  value       = module.this.nat_eip_public_ips
  description = "NAT EIP public IPs keyed by AZ"
}

output "nat_gateway_ids" {
  value       = module.this.nat_gateway_ids
  description = "NAT Gateway IDs keyed by AZ"
}

# Private route tables (map keyed by AZ of the private subnet)
output "private_route_table_ids" {
  value       = module.this.private_route_table_ids
  description = "Private route table IDs keyed by AZ"
}

output "ec2_security_group_id" {
  value       = module.this.ec2_security_group_id
  description = "Security group ID for EC2"
}
