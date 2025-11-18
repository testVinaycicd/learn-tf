data "vault_generic_secret" "smtp" {
  path = "infra/smtp"
}

data "template_file" "prom-stack" {
  template = file("${path.module}/helm-config/prom-stack-template.yml")
  vars = {
    SMTP_user_name = data.vault_generic_secret.smtp.data["username"]
    SMTP_password  = data.vault_generic_secret.smtp.data["password"]
  }
}

