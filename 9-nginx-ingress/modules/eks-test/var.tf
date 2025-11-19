
variable "env" {
  type        = string
  description = "Environment string (dev/prod)."
}

variable "name" {
  type    = string
  default = null
  description = "Optional cluster name. If null, module will use "
}


variable "eks_version" {
  type        = string
  description = "EKS control plane version (string like \"1.32\")."
}

variable "node_groups" {
  type        = map(any)
  description = "Map of node groups. Each value should be a map with min_nodes, max_nodes, instance_types (list), capacity_type (optional)."
}

variable "addons" {
  type        = map(any)
  description = "Map of addons to create (keys are addon names). Module will try to create aws_eks_addon for each key."
  default     = {}
}

variable "access" {
  type        = map(any)
  description = "Map of access principals. Each entry should contain a 'role' key with IAM role ARN to be granted cluster-admin."
  default     = {}
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs where EKS will place the control plane (vpc_config) and the nodegroups will use these subnets as well."
}

variable "tags" {
  type    = map(string)
  default = {}
  description = "Optional tags to add to created AWS resources."
}
