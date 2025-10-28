output "vpc_id" { value = aws_vpc.this.id }
output "public_subnets" { value = [for s in aws_subnet.public: s.id] }
output "sg_ec2_id" { value = aws_security_group.ec2_sg.id }


output "vpc_cidr" {
  value       = aws_vpc.this.cidr_block
  description = "VPC CIDR block"
}

output "vpc_ID" {
  value       = aws_vpc.this.id
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

output "ec2_security_group_id" {
  value       = aws_security_group.ec2_sg.id
  description = "Security group ID for EC2"
}
