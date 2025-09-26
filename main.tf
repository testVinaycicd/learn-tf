terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "my_instance" {
  ami = "ami-09c813fb71547fc4f"
  instance_type = var.instance_type
  tags = {
    Name = var.tag_name
  }
}

variable "instance_type" {
  description = "instance type"
  type = string
  default = "t2.micro"
}


resource "aws_iam_user" "new_users" {
  # count = length(var.user_names)
  for_each = toset(var.user_names)
  name = each.value
}

