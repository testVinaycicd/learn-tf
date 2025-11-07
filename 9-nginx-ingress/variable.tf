variable "aws_region" { type = string }

variable "vpc_cidr" {
  type = string
  default = "11.0.0.0/16"
}

variable "azs" {
  type = list(string)
  default = ["us-east-1a","us-east-1b"]
}

variable "name" {}

variable "access" {}

variable "addons" {}


variable "vault_token" {
  sensitive = true

}
