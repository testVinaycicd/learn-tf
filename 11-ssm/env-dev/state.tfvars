
aws_region = "us-east-1"


name = "terraform-learning-1"

access = {
  workstation = {
    role                    = "arn:aws:iam::633788536644:role/workstation-role"
    policy_arn              = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope_type       = "cluster"
    access_scope_namespaces = []
  }
  github_runner = {
    role                    = "arn:aws:iam::886436958775:role/github-runner-role"
    policy_arn              = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope_type       = "cluster"
    access_scope_namespaces = []
  }
}
