variable "aws_region" { type = string }
variable "instance_type" { type = string }


variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}
variable "azs" {
  type = list(string)
  default = ["us-east-2a","us-east-2b"]
}

variable "name" {}
