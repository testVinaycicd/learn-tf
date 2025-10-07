variable "aws_region" { type = string }


variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}
variable "azs" {
  type = list(string)
  default = ["us-east-1a","us-east-1b"]
}

variable "name" {}
variable "access" {}
variable "instance_type" {}