output "alb_dns_name" { value = aws_lb.this.dns_name }

output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_target_gp_arn" {
  value = aws_lb_target_group.tg.arn
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}