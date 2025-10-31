variable "ami_id" {}
variable "instance_type" {}
variable "name" {}
variable "zone_id" {}
variable "port" {}
variable "iam_policy" {
  type = map(list(string))
}
variable "root_block_device" {}

