terraform {
    backend "s3" {
        bucket = "learning-bucket-307"    # existing bucket
        key    = "terraform-module/infra-setup/vault.tfstate"
        region = "us-east-2"
    }
    required_providers {
        vault = {
            source  = "hashicorp/vault"
            version = "4.5.0"
        }
    }
}


provider "kubernetes" {}  # uses local kubeconfig

provider "vault" {
    address = var.vault_addr
    token   = var.vault_token
}

# ---------------- K8s: Token Reviewer SA + RBAC ----------------
resource "kubernetes_service_account" "reviewer" {
    metadata {
        name      = "vault-token-reviewer"
        namespace = "kube-system"
    }
}

resource "kubernetes_cluster_role_binding" "reviewer_binding" {
    metadata { name = "vault-token-reviewer-binding" }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind      = "ClusterRole"
        name      = "system:auth-delegator"
    }
    subject {
        kind      = "ServiceAccount"
        name      = kubernetes_service_account.reviewer.metadata[0].name
        namespace = kubernetes_service_account.reviewer.metadata[0].namespace
    }
}

# Long-lived SA token Secret (works on K8s 1.24+)
resource "kubernetes_secret" "reviewer_token" {
    metadata {
        name      = "vault-token-reviewer"
        namespace = "kube-system"
        annotations = {
            "kubernetes.io/service-account.name" = kubernetes_service_account.reviewer.metadata[0].name
        }
    }
    type = "kubernetes.io/service-account-token"
}

# Read token + CA from that Secret
data "kubernetes_secret" "reviewer_token" {
    metadata {
        name      = kubernetes_secret.reviewer_token.metadata[0].name
        namespace = kubernetes_secret.reviewer_token.metadata[0].namespace
    }
}

locals {
    reviewer_jwt = base64decode(data.kubernetes_secret.reviewer_token.data.token)
    k8s_ca_pem   = base64decode(data.kubernetes_secret.reviewer_token.data["ca.crt"])
}

# ---------------- Vault: enable + config K8s auth ----------------
resource "vault_auth_backend" "k8s" {
    type = "kubernetes"
    path = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "k8s" {
    backend              = vault_auth_backend.k8s.path
    kubernetes_host      = var.k8s_api_server
    kubernetes_ca_cert   = local.k8s_ca_pem
    token_reviewer_jwt   = local.reviewer_jwt
    issuer               = var.issuer
}

# Ensure KV v2 mount exists (skip if you already have it)
resource "vault_mount" "kv" {
    path        = var.kv_mount
    type        = "kv-v2"
    description = "App secrets"
}

# Least-privilege policy for your app subtree
resource "vault_policy" "readonly_app" {
    name   = "readonly-${var.team}-${var.app}"
    policy = <<-EOT
    path "${var.kv_mount}/data/${var.team}/${var.app}/*" {
      capabilities = ["read"]
    }
    path "${var.kv_mount}/metadata/${var.team}/${var.app}/*" {
      capabilities = ["read","list"]
    }
  EOT
}

# Role bound to your ESO SA in your app namespace
resource "vault_kubernetes_auth_backend_role" "eso_app" {
    backend                          = vault_auth_backend.k8s.path
    role_name                        = "eso-${var.team}-${var.app}"
    bound_service_account_names      = [var.eso_sa_name]
    bound_service_account_namespaces = [var.app_namespace]
    token_policies                   = [vault_policy.readonly_app.name]
    token_ttl                        = 1800 # 30m
}