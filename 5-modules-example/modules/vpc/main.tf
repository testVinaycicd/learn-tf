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
  cidr_block = cidrsubnet(var.cidr,8 ,each.value  )
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


resource "aws_subnet" "private" {
  for_each = local.az_map
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.cidr,8 ,each.value + 100 ) # separate /24 range, e.g., 10.0.100.0/24, 10.0.101.0/24
  availability_zone = each.key
  map_public_ip_on_launch = false
  tags = { Name = "${var.name}-private-${each.key}" }
}

resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = { Name = "${var.name}-nat-eip-${each.key}" }
}


# NAT belongs to public subnet (placement), but it serves private subnets (usage).
resource "aws_nat_gateway" "this" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id # nat gateway should live in a public subnet for it to access internet
  tags          = { Name = "${var.name}-nat-${each.key}" }

  depends_on = [aws_internet_gateway.this]
}


resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id
  tags     = { Name = "${var.name}-private-rt-${each.key}" }
}

resource "aws_route" "private_default_via_nat" {
  for_each               = aws_route_table.private
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}