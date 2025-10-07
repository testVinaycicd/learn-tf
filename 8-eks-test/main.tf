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

# resource "tls_private_key" "generated" {
#   algorithm = "RSA"
#   rsa_bits = 4096
# }
#
# resource "aws_key_pair" "mikey_key" {
#   public_key = tls_private_key.generated.public_key_openssh
#   key_name = "mikey-auto-key"
# }
#
# resource "local_file" "pem_file" {
#   filename = "${path.module}/mikey-auto-key.pem"
#   content = tls_private_key.generated.private_key_pem
#   file_permission = "0600"
#   directory_permission = "0700"
#
# }
#
# resource "aws_s3_object" "pem_to_s3" {
#   bucket = "learning-bucket-307"                      # existing bucket
#   key    = "keys/mikey-auto-key.pem"             # or add a timestamp if you want rotation
#   content = tls_private_key.generated.private_key_pem
#
#
#   tags = {
#     Purpose = "EC2 SSH private key"
#     Owner   = "Mikey"
#   }
# }
#
# # --- Get the latest Amazon Linux 2 AMI ---
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]
#
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

locals {
  instances = {
    front = { name = "front" }

  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "SSH in from my IP, SSH out to private hosts"
  vpc_id      = "vpc-0c31a6db3f85d3e72" # or your VPC id

  ingress {
    description = "SSH from my workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-sg" }
}

resource "aws_security_group" "private_sg" {
  name        = "private-ssh-from-bastion"
  description = "Allow SSH only from bastion SG"
  vpc_id      = "vpc-0c31a6db3f85d3e72" # same VPC

  ingress {
    description              = "SSH from bastion"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    security_groups          = [aws_security_group.bastion_sg.id] # <-- key
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "private-ssh-from-bastion" }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.servers
  domain   = "vpc"
  tags     = { Name = "bastion-eip" }
}

# --- Create 2 EC2 instances ---
resource "aws_instance" "servers" {
  ami                    = "ami-09c813fb71547fc4f"
  instance_type          = "t3.micro"
  # key_name               = aws_key_pair.mikey_key.key_name
  vpc_security_group_ids = ["sg-0ba190cf2e0769cc9",aws_security_group.bastion_sg.id]
  subnet_id = "subnet-021a482caefd9d301"

  tags = {
    Name        = "front"
    Environment = "dev"
    Prompt      = "front"
  }
}

resource "aws_instance" "servers_private" {

  ami                    = "ami-09c813fb71547fc4f"
  instance_type          = "t3.micro"
  # key_name               = aws_key_pair.mikey_key.key_name
  vpc_security_group_ids = ["sg-0ba190cf2e0769cc9",aws_security_group.private_sg.id]
  subnet_id = "subnet-08520f5eb31862969"

  tags = {
    Name        = "private instance"
    Environment = "dev"

  }
}

# resource "null_resource" "server_setup" {
#   for_each   = aws_instance.servers
#   depends_on = [aws_instance.servers]
#
#   triggers = {
#     instance_id_change = each.value.id
#   }
#   # connection {
#   #   type        = "ssh"
#   #   host        = each.value.public_ip
#   #   user        = "ec2-user"
#   #   private_key = tls_private_key.generated.private_key_pem
#   #   timeout     = "5m"
#   # }
#   connection {
#     type = "ssh"
#     user = "ec2-user"
#     password = "DevOps321"
#     timeout = "5m"
#   }
#
#
#   provisioner "remote-exec" {
#
#     inline = [
#       "set -euo pipefail",
#       # deps
#       "sudo yum -y install git",
#       # ansible 2.9 on AL2
#       "sudo amazon-linux-extras enable ansible2",
#       "sudo yum -y install ansible",
#       # run your playbook locally via ansible-pull
#       "ansible --version || true",
#       " sleep 5",
#       "ansible-pull  -U https://github.com/testVinaycicd/learn-tf.git -C main  -i localhost, 8-eks-test/setup.yaml  -e \"tool_name=${each.value.tags.Name}\" -e ansible_python_interpreter=/usr/bin/python3 "
#     ]
#
#
#   }
# }
