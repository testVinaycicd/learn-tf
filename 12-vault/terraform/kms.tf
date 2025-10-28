# ---------- KMS for Vault auto-unseal ----------

resource "aws_kms_key" "vault" {
  description             = "KMS key for Vault auto-unseal"
  deletion_window_in_days = var.kms_key_deletion_window_days
  enable_key_rotation     = true
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${var.name}-vault"
  target_key_id = aws_kms_key.vault.id
}