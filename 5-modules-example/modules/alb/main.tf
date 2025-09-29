terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
resource "aws_lb" "this" {
  name = "${var.name}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb-sg.id]
  subnets = var.subnets
  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_security_group" "alb-sg" {
  name   = "${var.name}-alb-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# you target group instances
resource "aws_lb_target_group" "tg" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/health"
    port = "80"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    matcher             = "200-399"
  }
}

# you mention what all instances needs to be in the target group
resource "aws_lb_target_group_attachment" "tga" {
  count = try(length(var.target_instance_ids), 0)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.target_instance_ids[count.index]
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
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
# ALB listens on port 80.
# Forwards traffic to the Target Group.
# Target Group distributes traffic to all attached EC2 instances (on port 80).
# ALB uses health checks to ensure only healthy instances receive traffic.