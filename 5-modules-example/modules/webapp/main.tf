data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
}



resource "aws_instance" "ec2_example" {

  ami = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = [var.security_group]
  iam_instance_profile = var.iam_instance_profile

  tags = {
    Name = var.name
  }

  user_data = <<-EOF
      #!/bin/bash
      set -euxo pipefail

      # Noninteractive frontend for apt (helps in cloud-init)
      export DEBIAN_FRONTEND=noninteractive

      # Update + install
      apt-get update -y
      apt-get install -y apache2

      # Ensure Apache enabled & started
      systemctl enable --now apache2

      # Write index.html safely (use tee with sudo if needed)
      cat > /var/www/html/index.html <<'HTML'
      <html>
        <body>
          <h1>Hello from module-1</h1>
          <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
          <p>Local IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</p>
        </body>
      </html>
      HTML

      # Adjust ownership/permissions (www-data is apache user on Debian/Ubuntu)
      chown -R www-data:www-data /var/www/html
      chmod -R 755 /var/www/html

      # Print status for cloud-init logs
      systemctl status apache2 --no-pager || true
      journalctl -u apache2 -n 200 --no-pager || true

      EOF
}


