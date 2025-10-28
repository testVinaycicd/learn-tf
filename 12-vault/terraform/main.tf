

# ---------- Security Groups ----------
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB SG"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP for redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from allowed CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "vault" {
  name        = "${var.name}-vault-sg"
  description = "Vault EC2 SG"
  vpc_id      = var.vpc_id
  ingress {
    description = "HTTPS from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ALB → Vault 8200 (TLS)
  ingress {
    description = "ALB to Vault 8200"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# ---------- ALB + Listener + Target Group ----------
resource "aws_lb" "vault" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = var.alb_internal
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_subnet_ids
}




resource "aws_lb_target_group" "vault_https" {
  name        = "vault-alb-https"         # keep your existing name if you like
  port        = 8200
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"

  # Optional: stick to HTTP/1 since Vault UI/HTTP API is classic
  protocol_version = "HTTP1"

  health_check {
    path                = "/v1/sys/health?standbyok=true&perfstandbyok=true"
    protocol            = "HTTPS"
    matcher             = "200,429,472,473"
    port                = "8200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.vault.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = var.acm_certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault_https.arn
  }
}


resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.vault.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ---------- Route53 ----------
resource "aws_route53_record" "vault" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name    = aws_lb.vault.dns_name   # e.g. vault-alb-123456.elb.amazonaws.com
    zone_id = aws_lb.vault.zone_id
    evaluate_target_health = true
  }
}

# vault.yourdomain.com (DNS in Route 53)
# ↓
# ALB DNS name
# ↓
# Listener :80 → redirect → :443
# ↓
# Listener :443 (ACM cert)
# ↓
# Target Group (Vault :8200)


resource "aws_instance" "vault" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.ec2_subnet_id
  vpc_security_group_ids      = [aws_security_group.vault.id]
  iam_instance_profile        = aws_iam_instance_profile.vault.name

  tags = {
    Name = "learning-vault"
  }

}


resource "null_resource" "frontend" {
  depends_on = [aws_route53_record.vault]

  triggers = {
    always = timestamp()  # changes on every apply → always re-run
  }

  provisioner "remote-exec" {

    connection {
      type     = "ssh"
      user     = "ec2-user"
      password = "DevOps321"
      host     = aws_instance.vault.public_ip
    }


    inline = [
      "sudo pip3.11 install ansible hvac",
      "until nslookup learn-vault.mikeydevops1.online; do echo 'Waiting for DNS...'; sleep 5; done",
      "git clone https://github.com/testVinaycicd/learn-tf.git",
      "cd ./learn-tf/12-vault",
      "ls",
      "ansible-pull -U https://github.com/testVinaycicd/learn-tf.git -C main -i localhost, 12-vault/vault_setup.yaml -e component_name=ansible -e tool_name=ansible"
    ]


  }
}


resource "aws_lb_target_group_attachment" "vault_http" {
  target_group_arn = aws_lb_target_group.vault_https.arn
  target_id        = aws_instance.vault.id
  port             = 8200
}
