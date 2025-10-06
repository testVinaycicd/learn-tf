terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
    local = { source = "hashicorp/local", version = "~> 2.4" }
  }
}


provider "aws" {
  region = var.region
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "mikey_key" {
  public_key = tls_private_key.generated.public_key_openssh
  key_name = "mikey-auto-key"
}

resource "local_file" "pem_file" {
  filename = "${path.module}/mikey-auto-key.pem"
  content = tls_private_key.generated.private_key_pem
  file_permission = "0600"
  directory_permission = "0700"

}

# --- Get the latest Amazon Linux 2 AMI ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# --- Create 2 EC2 instances ---
resource "aws_instance" "servers" {
  count                  = 2
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.mikey_key.key_name
  vpc_security_group_ids = ["sg-075a6c6cca025aa34"]

  tags = {
    Name        = "mikey-server-${count.index + 1}"
    Environment = "dev"
  }
}