variable "region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region"
}

variable "vpc_id" {
  default = "vpc-02832062d98cfc0d9"
}

variable "cluster_name" {
  type        = string
  default     = "mikey-eks"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.34"
}

# IMPORTANT: pass **PUBLIC** subnet IDs here for Level-1
variable "subnet_ids" {
  type = list(string)
  description = "Public subnet IDs (with IGW route)"
  default = ["subnet-0d264101827d0b903","subnet-084c2ee69edcd686d"]
}
# Lock the public endpoint to your current public IP if you can.
# For quick tests you can use 0.0.0.0/0, but it's not recommended.
variable "public_access_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs in at least two AZs (with NAT route)"
  default = ["subnet-0d3eaa9f19a424848","subnet-0eb1866dc38bb339f"]
}

variable "access" {}