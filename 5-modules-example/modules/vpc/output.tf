output "vpc_id" { value = aws_vpc.this.id }
output "public_subnets" { value = [for s in aws_subnet.public: s.id] }
output "sg_ec2_id" { value = aws_security_group.ec2_sg.id }
