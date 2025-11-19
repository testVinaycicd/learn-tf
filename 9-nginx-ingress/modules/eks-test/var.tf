variable "env" {}
variable "eks_version" {}
variable "node_groups" {}
variable "addons" {}
variable "access" {}
variable "subnet_ids" {}
variable "tags" {
  type        = map(string)
  description = "Optional tags to add to created AWS resources (merged with default tags)."
  default     = {}
}