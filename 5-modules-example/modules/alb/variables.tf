variable "name" {}
variable "subnets" { type = list(string) }
variable "target_instance_ids" { type = list(string) }
variable "vpc_id" {}
