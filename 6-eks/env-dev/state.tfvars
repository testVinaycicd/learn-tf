
region             = "us-east-2"
cluster_name       = "mikey-eks"
kubernetes_version = "1.30"
vpc_id             = "vpc-0a05ed25fa5ee7713"
private_subnet_ids = ["subnet-059376aad9737ac30", "subnet-0a7de61b17306b32f"]
admin_principal_arn = "arn:aws:sts::886436958775:assumed-role/workstation-role/i-024c58e8e6fb2c0ae"
# For temporary public API access (not recommended long-term):
endpoint_private_access = true
endpoint_public_access  = false
# endpoint_public_cidrs = ["10.0.0.0/24","10.0.1.0/24"]