provider "aws" {
  region = var.aws_region
}



terraform {
  backend "s3" {
    bucket         = "learning-bucket-307"    # existing bucket
    key            = "terraform-module/test/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = true
  }
}

