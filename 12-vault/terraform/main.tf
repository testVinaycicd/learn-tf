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

# ---------- Security Groups ----------
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB SG"
  vpc_id      = var.vpc_id

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

# ---------- IAM for EC2 (KMS + SSM) ----------
resource "aws_iam_role" "vault" {
  name               = "${var.name}-vault-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}


data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "minimal_role" {
  name = "${var.name}-minimal_roal"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:*",
          "elasticloadbalancing:*",
          "iam:*",
          "kms:*",
          "route53:*",
          "ssm:*",
          "cloudwatch:*",
          "logs:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "minimal_role" {
  role       = aws_iam_role.vault.name
  policy_arn = aws_iam_policy.minimal_role.arn
}


resource "aws_iam_instance_profile" "vault" {
  name = "${var.name}-vault-instance-profile"
  role = aws_iam_role.vault.name
}

# ---------- ALB + Listener + Target Group ----------
resource "aws_lb" "vault" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = var.alb_internal
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_subnet_ids
}


resource "aws_lb_target_group" "vault" {
  name        = "${var.name}-tg"
  port        = 8200
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = "/v1/sys/health"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTPS"
    matcher             = "200-399"
    port                = "8200"
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
    target_group_arn = aws_lb_target_group.vault.arn
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
    instance_id_change = aws_instance.vault.id
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
      "ansible-pull -i localhost, -U https://github.com/testVinaycicd/learn-tf.git 12-vault/vault_setup.yml -e component_name=ansible -"
    ]


  }
}


resource "aws_lb_target_group_attachment" "vault" {
  target_group_arn = aws_lb_target_group.vault.arn
  target_id        = aws_instance.vault.id
  port             = 8200
}















































