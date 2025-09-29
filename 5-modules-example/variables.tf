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
variable "subnet_id" {}
variable "security_group" {}
variable "iam_instance_profile" {
  type    = string
  default = ""
}
