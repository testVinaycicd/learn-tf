locals {
  cluster_name = "eks-${var.env}"

}

# IAM role for the EKS control plane
resource "aws_iam_role" "eks_cluster" {
  name = "${local.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = var.env
}

resource "aws_iam_role_policy_attachment" "eks_cluster_attach" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM role for nodes (managed node group role)
resource "aws_iam_role" "node_role" {
  name = "${local.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.env
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = var.subnet_ids
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  tags =  var.env

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_attach
  ]
}

# Create addons if requested (note: only valid addon names accepted by AWS will succeed)
resource "aws_eks_addon" "addons" {
  for_each = var.addons
  cluster_name = aws_eks_cluster.this.name
  addon_name   = each.key
  # version left to default/latest — you can pass more info in var.addons value if needed
  tags =  var.env
  depends_on = [aws_eks_cluster.this]
}

# Managed node groups — create one resource per entry in var.node_groups
resource "aws_eks_node_group" "node_groups" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = lookup(each.value, "desired", lookup(each.value, "min_nodes", 1))
    max_size     = lookup(each.value, "max_nodes", 2)
    min_size     = lookup(each.value, "min_nodes", 1)
  }

  instance_types = lookup(each.value, "instance_types", ["t3.medium"])
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")

  tags = merge( var.env, { "eks:nodegroup" = each.key })

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy
  ]
}

# Data source to create a kube token for the kubernetes provider
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.this.name
  depends_on = [aws_eks_cluster.this]
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.this.name
}

# Build mapRoles for aws-auth: node role + any access roles passed in var.access
locals {
  map_roles = concat(
    [
      {
        rolearn  = aws_iam_role.node_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ],
    [
      for k, v in var.access :
      {
        rolearn  = lookup(v, "role", "")
        username = "admin"
        groups   = ["system:masters"]
      }
      if lookup(v, "role", "") != ""
    ]
  )
}


# Create / manage the aws-auth configmap so nodes + admin roles can access the cluster
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(local.map_roles)
  }

  # ensure cluster + nodegroup finished creating before managing aws-auth
  depends_on = [
    aws_eks_node_group.node_groups
  ]
}
