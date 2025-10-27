variable "ami_id" {
  default = "ami-09c813fb71547fc4f"
}



variable "zone_id" {
  default = "Z09180393TY9K7UQDKE5E"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "name" {
  type = string
  default = "vault"
}

variable "vpc_id"{
  type = string
}


variable "alb_subnet_ids" {
  type = list(string)
}

variable "ec2_subnet_id" {
  type = string
}


variable "route53_zone_id" {
  type = string
}
variable "domain_name" {
  default = "learn-vault.mikeydevops1.online"
} # e.g., "vault.example.com"

variable "acm_certificate_arn" {
  type = string
} # ACM cert in same region


variable "alb_internal" {
  type    = bool
  default = false
}

variable "alb_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "alb_allowed_cidrs" {
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "instance_type" {
  type = string
  default = "t3.small"
}

variable "kms_key_deletion_window_days" {
  type = number
  default = 30
}