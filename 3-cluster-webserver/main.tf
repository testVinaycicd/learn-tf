terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
provider "aws" {
  region = "eu-west-1"

}

data "aws_availability_zones" "all" {}

resource "aws_security_group" "instance_sg" {
  name = "sample-security-group-instance"

  ingress {
    from_port = var.instance_port
    to_port = var.instance_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "elb_sg" {
  name = "sample-security-group-elb"

  ingress {
    from_port = var.elb_port
    to_port = var.elb_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_launch_configuration" "example_instance" {
  ami = "ami-09c813fb71547fc4f"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance_sg]
  user_data = file("${path.module}/userdata.sh")


  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "example_instance_auto_scaling" {
  launch_configuration = aws_launch_configuration.example_instance.id
  availability_zones = [data.aws_availability_zones.all.names]

  load_balancers = [aws_elb.example_elb.name]

  max_size = 2
  min_size = 10

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "Terraform-asg-example"
  }

}

resource "aws_elb" "example_elb" {

  name = "terraform-elb"
  availability_zones = [data.aws_availability_zones.all.names]
  security_groups = [aws_security_group.elb_sg]

  listener {
    instance_port     = var.instance_port
    instance_protocol = "http"
    lb_port           = var.elb_port
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    interval            = 30
    target              = "HTTP:${var.instance_port}"
    timeout             = 3
    unhealthy_threshold = 2
  }

}
















































