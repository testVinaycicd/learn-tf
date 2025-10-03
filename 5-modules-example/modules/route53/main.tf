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
#  request a cert in ACM
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
# proof of ownership
# ensures certs are renewed automatically
# creates cname
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

#  checks the proof of ownership that is created and terraform waits for acm validation
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
# attach validated cert to alb and now alb can serve https traffic with that cert
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
# with this we can automate alb to our own dns name
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


# when the traffic hits this domain
# the traffic request acm to talk to my domain secretly so it shows the certificate
# alc decrypt the traffic ( the termination point )
# at this point alb has plain http traffic and it forwards it to ec2 instances over ports 80 inside my vpc

# So the ALB is the TLS terminator.
#T he EC2s don’t need to know anything about HTTPS — they just serve normal HTTP.