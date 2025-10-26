output "vault_url" {
  value = "https://${var.domain_name}" description = "Public URL via ALB"
}

output "vault_instance_id" {
  value = aws_instance.vault.id
}

output "kms_key_arn" {
  value = aws_kms_key.vault.arn
}