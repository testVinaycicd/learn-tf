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

resource "null_resource" "server_setup" {
  depends_on = [aws_instance.servers]

  triggers = {
    instance_id_change = aws_instance.servers.id
  }

  provisioner "remote-exec" {

    inline = [
      "aws s3 cp s3://learning-bucket-307/keys/mikey-auto-key.pem .",
      "chmod 600 mikey-auto-key.pem",
      "PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)",
      "ssh -i mikey-auto-key.pem ec2-user@PUBLIC_IP",
      "sudo pip3.11 install ansible hvac",
      " do echo 'Waiting for DNS...'; sleep 5; done",
      "ansible-playbook -i localhost, setup-tool.yml  -e tool_name=instance "
    ]


  }
}
