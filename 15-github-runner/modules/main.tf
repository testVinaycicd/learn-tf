terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
resource "aws_security_group" "tools" {
  name        = "${var.name}-sg"
  description = "${var.name} security group "


}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.tools.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
  description = "ssh"
}

resource "aws_vpc_security_group_ingress_rule" "app_port" {
  security_group_id = aws_security_group.tools.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = var.port
  ip_protocol = "tcp"
  to_port = var.port
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.tools.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1" #means all
}

resource "aws_instance" "tool" {

  ami = var.ami_id # Amazon Linux 2 AMI in us-east-1
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.tools.id]
  iam_instance_profile = aws_iam_instance_profile.main.name

  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "stop"
      spot_instance_type = "persistent"
    }
  }

  root_block_device {
    volume_size = var.root_block_device
  }

  tags = {
    Name = " ${ var.name }-terraform "
  }
}


resource "aws_route53_record" "private" {

  zone_id = var.zone_id
  name    = "${var.name}-internal"
  type    = "A"
  ttl     = 10
  records = [aws_instance.tool.private_ip]
}


resource "aws_route53_record" "public" {
  # count   = aws_instance.tool.public_ip != null ? 1 : 0
  zone_id = var.zone_id
  name    = var.name
  type    = "A"
  ttl     = 10
  records = [aws_instance.tool.public_ip]
}

