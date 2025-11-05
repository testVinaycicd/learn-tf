terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }

}

provider "aws" {
  region = var.region
}

resource "aws_eks_addon" "addons" {
  for_each = var.addons
  cluster_name = aws_eks_cluster.this.name
  addon_name   = each.key
}

# --- EKS Cluster (EKS will create & wire SGs automatically) ---
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks.arn
  version  = var.kubernetes_version


  vpc_config {
    subnet_ids               = var.private_subnet_ids
    endpoint_private_access  = true
    endpoint_public_access   = true
    public_access_cidrs      = ["98.84.127.208/32"]
  }


  access_config {
    authentication_mode                           = "API"
    bootstrap_cluster_creator_admin_permissions   = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# --- Managed Node Group (EKS chooses AL2023 by default) ---
resource "aws_eks_node_group" "default" {
  cluster_name   = aws_eks_cluster.this.name
  node_role_arn  = aws_iam_role.nodes.arn
  subnet_ids     = var.private_subnet_ids
  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = 3
    min_size     = 2
    max_size     = 10
  }

  launch_template {
    id = aws_launch_template.ng.id
    version = "$Latest"
  }

  capacity_type = "SPOT" # keep simple/reliable for first bring-up

  update_config { max_unavailable = 1 }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.node_eks_worker,
    aws_iam_role_policy_attachment.node_ecr_readonly,
    aws_iam_role_policy_attachment.node_cni
  ]



}


# ebs csi driver
resource "aws_eks_access_entry" "main" {
  for_each          = var.access
  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value["role"]
  type              = "STANDARD"
}




# giving access policy for other roles
resource "aws_eks_access_policy_association" "main" {
  for_each      = var.access
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = each.value["policy_arn"]
  principal_arn = each.value["role"]

  access_scope {
    type       = each.value["access_scope_type"]
    namespaces = each.value["access_scope_namespaces"]
  }
}
