terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.81.0, <= 5.100.0"   # or "5.100.0"
    }

  }

  backend "s3" {
    bucket = "learning-bucket-307"    # existing bucket
    key          = "terraform-module/eks/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }


}


provider "aws" {
  region = var.aws_region
}


provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

