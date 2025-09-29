output "check-webserver" {
  value = module.web-server-1.public_ip
}

output "alb_dns" {
  value = module.alb.alb_dns_name
}
