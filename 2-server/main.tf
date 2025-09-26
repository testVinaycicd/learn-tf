terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
provider "aws" {
  region = "eu-west-1"
}


resource "aws_instance" "main" {
  ami = "ami-09c813fb71547fc4f"
  instance_type = "t2.micro"
  user_data = file("${path.module}/userdata.sh")
  tags = {
    name = "learn-web-server"
  }

  vpc_security_group_ids = [aws_security_group.instance.id]

}

resource "aws_security_group" "instance" {
  name = "sample-security-group"
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

output "public_ip" {
  value = aws_instance.main.public_ip
}