terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
resource "aws_vpc" "this" {
  cidr_block = var.cidr
  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-igw"
  }
}

locals {
# {
# "us-east-1a" = 0
# "us-east-1b" = 1
# "us-east-1c" = 2
# }
  az_map = { for idx, az in var.azs : az => idx }
}


# Subnet in us-east-1a gets index 0 → 10.0.0.0/24
# Subnet in us-east-1b gets index 1 → 10.0.1.0/24

resource "aws_subnet" "public" {
  for_each = local.az_map
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.cidr,8 ,each.value)
  availability_zone = each.key
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${each.key}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.name}-public-rt" }
}

# so we created 1 subnet each for 2 az and we are telling these subnets is routed through igw
resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2_sg" {
  name   = "${var.name}-ec2-sg"
  vpc_id = aws_vpc.this.id
  description = "Allow ssh/http from ALB"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # lock down in prod
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.name}-ec2-sg" }
}