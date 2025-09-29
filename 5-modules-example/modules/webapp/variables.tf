variable "name" { type = string, default = "demo" }
variable "ami" { type = string, default = "" }    # set to an AMI for your region or use data source
variable "instance_type" { type = string, default = "t3.micro" }
variable "user_data" { type = string, default = "" }

variable "subnet_id" {}
variable "iam_instance_profile" {}
