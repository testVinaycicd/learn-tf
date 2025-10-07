terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
  backend "s3" {
    bucket = "learning-bucket-307"    # existing bucket
    key          = "terraform-module/test/terraform-eks-level-1.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

# --- EKS Cluster IAM Role ---
data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- EKS Cluster (EKS will create & wire SGs automatically) ---
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks.arn
  version  = var.kubernetes_version


  vpc_config {
    subnet_ids               = var.private_subnet_ids
    endpoint_private_access  = true
    endpoint_public_access   = false
    # public_access_cidrs      = ["3.85.169.228/32"]
  }


  access_config {
    authentication_mode                           = "API"
    bootstrap_cluster_creator_admin_permissions   = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# --- Node group IAM role ---
data "aws_iam_policy_document" "nodes_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nodes" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.nodes_assume.json
}

# Minimal 3 policies for managed nodes
resource "aws_iam_role_policy_attachment" "node_eks_worker" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "node_ecr_readonly" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_launch_template" "ng" {
  name_prefix = "${var.cluster_name}-ng-"
  vpc_security_group_ids = [aws_security_group.nodes.id]
}


# --- Managed Node Group (EKS chooses AL2023 by default) ---
resource "aws_eks_node_group" "default" {
  cluster_name   = aws_eks_cluster.this.name
  node_role_arn  = aws_iam_role.nodes.arn
  subnet_ids     = var.private_subnet_ids
  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 6
  }

  launch_template {
    id = aws_launch_template.ng.id
    version = "$Latest"
  }

  capacity_type = "ON_DEMAND" # keep simple/reliable for first bring-up

  update_config { max_unavailable = 1 }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.node_eks_worker,
    aws_iam_role_policy_attachment.node_ecr_readonly,
    aws_iam_role_policy_attachment.node_cni
  ]



}

# Nodes SG
resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes"
  description = "EKS nodes security group"
  vpc_id      = var.vpc_id
  egress {
    from_port=0
    to_port=0
    protocol="-1"
    cidr_blocks=["0.0.0.0/0"]
  }
}

# Control plane -> nodes (kubelet)
resource "aws_security_group_rule" "cluster_to_nodes_kubelet" {
  type="ingress"
  from_port=10250
  to_port=10250
  protocol="tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

# Node-to-node
resource "aws_security_group_rule" "nodes_within_group_all" {
  type="ingress"
  from_port=0
  to_port=0
  protocol="-1"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.nodes.id
}

# Nodes -> API (443) by allowing on the cluster SG
resource "aws_security_group_rule" "nodes_to_api" {
  type="ingress"
  from_port=443
  to_port=443
  protocol="tcp"
  security_group_id        = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.nodes.id
}


#########################################
resource "aws_eks_access_entry" "main" {
  for_each          = var.access
  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value["role"]
  type              = "STANDARD"
}

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


############################
# IRSA (OIDC provider)
############################
# normally pods cant access aws services without credentials
# with aws_iam_openid_connect_provider
### kubernetes service accounts can assume iam roles directly
### pods get temp aws credentials automatically
### no need to hardcode keys in pods

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [] # AWS managed trust; omit unless your org mandates fixed thumbprints
  depends_on      = [aws_eks_cluster.this]
}