variable "region" {
  type = string
  default = "us-east-1"
}
variable "environment" {
  type = string
  default = "dev"
}
variable "instance_type" {
  type = string
  default = "t3.micro"
}
# variable "vpc_id"        { type = string }
# variable "subnet_id"     { type = string }
# variable "my_ip_cidr"    { type = string  description = "Your IP in CIDR, e.g. 1.2.3.4/32" }
variable "my_ip" {
  description = "Your public IP in CIDR"
  type        = string
  default = "54.205.231.96"
  # example: "203.0.113.45/32"
}