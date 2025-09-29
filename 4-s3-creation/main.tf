
provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "learning-bucket-307"
  force_destroy = true

  tags = {
    Name = "learning-bucket-307"
  }
}

resource "aws_s3_bucket_versioning" "version" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }

}