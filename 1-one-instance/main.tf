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

}