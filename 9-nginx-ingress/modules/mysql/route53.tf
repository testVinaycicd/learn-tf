resource "aws_route53_zone" "internal" {
  name = "shipping-internal"
  vpc  {
    vpc_id = var.vpc_id
  }
  comment = "Private zone for internal service discovery"
}

# CNAME record: mysql.shipping.internal.mikey.local -> RDS endpoint
resource "aws_route53_record" "mysql_private" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "mysql-dev.shipping.mikeydevops1.online"
  type    = "CNAME"
  ttl     = 60
  records = [aws_db_instance.shipping.address]  # e.g., shipping-mysql.xxxxxx.ap-south-1.rds.amazonaws.com
}