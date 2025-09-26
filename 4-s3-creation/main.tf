
provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "learning-bucket"
  force_destroy = true

  tags = {
    Name = "learning-bucket"
  }
}
