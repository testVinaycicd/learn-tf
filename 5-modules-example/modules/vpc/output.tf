output "vpc_id" { value = aws_vpc.this.id }
output "public_subnets" { value = [for s in aws_subnet.public: s.id] }
output "sg_ec2_id" { value = aws_security_group.ec2_sg.id }


output "vpc_cidr" {
  value       = aws_vpc.this.cidr_block
  description = "VPC CIDR block"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.this.id
  description = "Internet Gateway ID"
}

# Public subnets (map keyed by AZ)
output "public_subnet_ids" {
  value       = { for az, s in aws_subnet.public : az => s.id }
  description = "Public subnet IDs keyed by AZ"
}

output "public_subnet_cidrs" {
  value       = { for az, s in aws_subnet.public : az => s.cidr_block }
  description = "Public subnet CIDRs keyed by AZ"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

# Private subnets (map keyed by AZ)
output "private_subnet_ids" {
  value       = { for az, s in aws_subnet.private : az => s.id }
  description = "Private subnet IDs keyed by AZ"
}

output "private_subnet_cidrs" {
  value       = { for az, s in aws_subnet.private : az => s.cidr_block }
  description = "Private subnet CIDRs keyed by AZ"
}

# NAT resources (maps keyed by the AZ key used for public subnets)
output "nat_eip_allocation_ids" {
  value       = { for az, e in aws_eip.nat : az => e.id }
  description = "NAT EIP allocation resource IDs keyed by AZ"
}

output "nat_eip_public_ips" {
  value       = { for az, e in aws_eip.nat : az => e.public_ip }
  description = "NAT EIP public IPs keyed by AZ"
}

output "nat_gateway_ids" {
  value       = { for az, n in aws_nat_gateway.this : az => n.id }
  description = "NAT Gateway IDs keyed by AZ"
}

# Private route tables (map keyed by AZ of the private subnet)
output "private_route_table_ids" {
  value       = { for az, rt in aws_route_table.private : az => rt.id }
  description = "Private route table IDs keyed by AZ"
}

output "ec2_security_group_id" {
  value       = aws_security_group.ec2_sg.id
  description = "Security group ID for EC2"
}
