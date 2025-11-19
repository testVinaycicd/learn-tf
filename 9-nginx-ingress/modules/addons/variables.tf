
variable "cluster_name" {
  type        = string
  default     = "dev"
}

variable "vault_token" {
  sensitive = true
}