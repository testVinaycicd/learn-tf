terraform {
  backend "s3" {
    bucket = "tf-state-test"
    key = "terraform/dev/terraform.tfstate"
    region = "eu-west-1"
    dynamodb_table = "tf-state-test-lock"
    encrypt = true

  }
}