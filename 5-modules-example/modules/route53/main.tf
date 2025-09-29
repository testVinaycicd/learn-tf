############################################
# 1) Hosted zone (already exists)
############################################
data "aws_route53_zone" "primary" {
  name         = "mikeydevops1.online."
  private_zone = false
}

############################################
# 2) ACM certificate for subdomain
############################################
resource "aws_acm_certificate" "site" {
  domain_name       = "test-1-tera.mikeydevops1.online"
  validation_method = "DNS"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record in your hosted zone
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "site" {
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

############################################
# 3) ALB Listeners (HTTP → HTTPS, then HTTPS)
############################################
# resource "aws_lb_listener" "http" {
#   load_balancer_arn = var.alb_arn
#   port              = 80
#   protocol          = "HTTP"
#
#   default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

resource "aws_lb_listener" "https" {
  load_balancer_arn = var.alb_arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = aws_acm_certificate_validation.site.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.aws_lb_target_group
  }
}

############################################
# 4) Route 53 record for subdomain
############################################
resource "aws_route53_record" "subdomain" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "test-1-tera.mikeydevops1.online"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}