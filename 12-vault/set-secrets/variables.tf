variable "vault_addr"     { type = string }
variable "vault_token"    { type = string }    # admin/bootstrap token (or set VAULT_TOKEN env)
variable "issuer"         { type = string }    # EKS OIDC issuer, e.g. "https://oidc.eks.us-east-1.amazonaws.com/id/XXXX"
variable "k8s_api_server" { type = string }    # e.g. from kubectl config view --minify

variable "kv_mount" {
  type    = string
  default = "kv"
}

variable "team" {
  type    = string
  default = "myteam"
}

variable "app" {
  type    = string
  default = "myapp"
}

variable "app_namespace" {
  type    = string
  default = "prod"
}
variable "eso_sa_name" {
  type    = string
  default = "eso-myapp-sa"
}