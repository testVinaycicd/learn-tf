

variable "region"            { default = "us-east-1" }
variable "vpc_id"            { type = string }
variable "private_subnet_id" { type = string }
variable "vpc_cidr"          { type = string }

# Security group for the instance: block inbound, allow HTTPS out
resource "aws_security_group" "ec2" {
  name        = "ec2-ssm-private"
  description = "No inbound; egress 443 for SSM/endpoints"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-ec2-ssm-private" }
}

# SG for VPC Interface Endpoints (you can reuse an existing one)
resource "aws_security_group" "vpce" {
  name   = "ec2-ssm-private-vpc"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # tighten to your VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-vpce-ssm" }
}

# Interface endpoints (create only if you don't already have them)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.private_subnet_id]
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.private_subnet_id]
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.private_subnet_id]
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
}

# Gateway endpoint for S3 (helps with agent, patching, etc.)
data "aws_route_tables" "all" {
  vpc_id = var.vpc_id
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.all.ids
}

# IAM: SSM + minimal EKS describe for kubeconfig generation
data "aws_iam_policy" "ssm_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-ssm-eks-reader"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = data.aws_iam_policy.ssm_core.arn
}

# allow just DescribeCluster (least-priv)
resource "aws_iam_role_policy" "eks_describe" {
  name = "eks-describe-only"
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["eks:DescribeCluster"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "ec2-ssm-eks-reader"
  role = aws_iam_role.ec2_role.name
}

# Latest AL2023 AMI
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "bastionless_priv" {
  ami                         = "ami-09c813fb71547fc4f"
  instance_type               = "t3.micro"
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.this.name
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  metadata_options { http_tokens = "required" }
  tags = { Name = "eks-access-check" }
}

output "instance_id" { value = aws_instance.bastionless_priv.id }
