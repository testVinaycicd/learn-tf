
variable "cluster_name" {
  type        = string
  default     = "eks-dev"
}

variable "vault_token" {
  sensitive = true
}