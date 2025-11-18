resource "aws_instance" "instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = var.subnet_ids[0]

  root_block_device {
    volume_size = var.root_volume_size
    encrypted   = true
    kms_key_id  = var.kms_arn
  }

  tags = {
    Name    = var.name
    monitor = "true"
  }
}

resource "aws_security_group" "main" {
  name        = "${var.name}-sg"
  description = "${var.name}-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  for_each          = var.bastion_ssh_nodes
  description       = each.key
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = each.value
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  tags = {
    Name = each.key
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_db" {
  for_each          = var.app_cidr
  description       = each.key
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = each.value
  from_port         = var.port
  ip_protocol       = "tcp"
  to_port           = var.port
  tags = {
    Name = each.key
  }
}

resource "aws_route53_record" "record" {
  depends_on = [aws_instance.instance]
  zone_id = var.zone_id
  name    = "${var.name}-${var.env}"
  type    = "A"
  ttl     = 10
  records = [aws_instance.instance.private_ip]
}

resource "null_resource" "main" {
  depends_on = [aws_route53_record.record]

  triggers = {
    # instance_id_change = aws_instance.instance.id
    always = timestamp()
  }

  provisioner "remote-exec" {

    connection {
      type     = "ssh"
      user     = "ec2-user"
      password = "DevOps321"
      host     = aws_instance.instance.private_ip
    }

    inline = [
      "sudo pip3.11 install ansible hvac",
      "sudo set-prompt check",
      "ansible-pull -i localhost, -U https://github.com/testVinaycicd/learn-tf.git 9-nginx-ingress/modules/dbs/setup.yaml setup.yaml -e component_name=${var.ansible_role} -e env=${var.env} -e vault_token=${var.vault_token} --check",
    ]
  }
}