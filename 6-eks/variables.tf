variable "region"              { type = string }
variable "cluster_name"        { type = string }
variable "kubernetes_version"  { type = string  } # update as needed

variable "vpc_id"              { type = string }
variable "private_subnet_ids"  { type = list(string) }
variable "public_subnet_ids"   {
  type = list(string)
  default = []
} # if you plan public ALBs

# API endpoint exposure
variable "endpoint_private_access" {
  type = bool
  default = true
}
variable "endpoint_public_access"  {
  type = bool
  default = false
}
 # variable "endpoint_public_cidrs"   { type = list(string)  } # tighten if you enable public

# Node group
variable "node_instance_types" {
  type = list(string)
  default = ["t2.micro"]
}
variable "node_desired_size"   {
  type = number
  default = 2
}
variable "node_min_size"       {
  type = number
  default = 2
}
variable "node_max_size"       {
  type = number
  default = 6
}

# Admin access principal (IAM role/user ARN) to bootstrap cluster- admin
variable "admin_principal_arn" { type = string }

# Tags
variable "tags" {
  type = map(string)
  default = {}
}
