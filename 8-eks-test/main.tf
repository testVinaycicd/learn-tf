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

resource "aws_s3_object" "pem_to_s3" {
  bucket = "learning-bucket-307"                      # existing bucket
  key    = "keys/mikey-auto-key.pem"             # or add a timestamp if you want rotation
  content = tls_private_key.generated.private_key_pem


  tags = {
    Purpose = "EC2 SSH private key"
    Owner   = "Mikey"
  }
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

locals {
  instances = {
    front = { name = "front" }
    cat   = { name = "cat" }
  }
}

# --- Create 2 EC2 instances ---
resource "aws_instance" "servers" {
  for_each               = local.instances
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.mikey_key.key_name
  vpc_security_group_ids = ["sg-075a6c6cca025aa34"]

  tags = {
    Name        = each.value.name
    Environment = "dev"
    Prompt      = each.value.name
  }
}

resource "null_resource" "server_setup" {
  for_each   = aws_instance.servers
  depends_on = [aws_instance.servers]

  triggers = {
    instance_id_change = each.value.id
  }
  connection {
    type        = "ssh"
    host        = each.value.public_ip
    user        = "ec2-user"
    private_key = tls_private_key.generated.private_key_pem
    timeout     = "5m"
  }


  provisioner "remote-exec" {

    inline = [
      "set -euo pipefail",
      # deps
      "sudo yum -y install git",
      # ansible 2.9 on AL2
      "sudo amazon-linux-extras enable ansible2",
      "sudo yum -y install ansible",
      # run your playbook locally via ansible-pull
      "ansible --version || true",
      " sleep 5",
      "ansible-pull  -U https://github.com/testVinaycicd/learn-tf.git -C main  -i localhost, 8-eks-test/setup.yaml  -e \"tool_name=${each.value.tags.Name}\" -e ansible_python_interpreter=/usr/bin/python3 "
    ]


  }
}
