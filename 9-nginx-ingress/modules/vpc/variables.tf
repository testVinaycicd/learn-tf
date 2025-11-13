variable "name" {
  type    = string
  default = "myenv"
}

variable "cidr" {
  type    = string
  default = "11.200.0.0/16"
}
#
variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}


variable "vpc_cidr" {}
variable "env" {}
variable "subnets" {}
variable "default_vpc" {}