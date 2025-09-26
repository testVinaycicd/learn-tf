terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.60, < 6.0"
    }
  }

  backend "s3" {
    bucket         = "example-module"     # existing bucket
    key            = "terraform-module/test/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "tf-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}