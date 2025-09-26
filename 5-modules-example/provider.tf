provider "aws" {
  region = var.aws_region
}



terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.60, < 6.0"
    }
  }

  backend "s3" {
    bucket         = "learning-bucket"    # existing bucket
    key            = "terraform-module/test/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}

