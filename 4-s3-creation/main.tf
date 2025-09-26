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

resource "aws_s3_bucket" "tfstate" {
  bucket = "example-module"

  tags = {
    Name = "terraform-state"
  }
}
