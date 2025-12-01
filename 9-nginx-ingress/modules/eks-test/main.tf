data "http" "myip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  cluster_name = "eks-${var.env}"
  merged_tags  = merge({ Name = local.cluster_name, Env = var.env }, var.tags)
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

  tags = local.merged_tags
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

  tags = local.merged_tags
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

resource "aws_iam_role" "external-dns" {
  name = "${var.env}-eks-external-dns-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "pods.eks.amazonaws.com"
        },
        "Action" : [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external-dns-route53-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = aws_iam_role.external-dns.name
}

resource "aws_iam_role" "k8s-prometheus" {
  name = "${var.env}-eks-prometheus-server-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "pods.eks.amazonaws.com"
        },
        "Action" : [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

# data "aws_iam_policy_document" "cluster_autoscaler" {
#   version = "2012-10-17"
#
#   statement {
#     effect = "Allow"
#
#     actions = [
#       "autoscaling:SetDesiredCapacity",
#       "autoscaling:TerminateInstanceInAutoScalingGroup"
#     ]
#
#     resources = ["*"]
#
#     condition {
#       test     = "StringEquals"
#       variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"
#       values   = ["true"]
#     }
#
#     condition {
#       test     = "StringEquals"
#       variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/my-cluster"
#       values   = ["owned"]
#     }
#   }
#
#   statement {
#     effect = "Allow"
#
#     actions = [
#       "autoscaling:DescribeAutoScalingGroups",
#       "autoscaling:DescribeAutoScalingInstances",
#       "autoscaling:DescribeLaunchConfigurations",
#       "autoscaling:DescribeScalingActivities",
#       "autoscaling:DescribeTags",
#       "ec2:DescribeImages",
#       "ec2:DescribeInstanceTypes",
#       "ec2:DescribeLaunchTemplateVersions",
#       "ec2:GetInstanceTypesFromInstanceRequirements",
#       "eks:DescribeNodegroup"
#     ]
#
#     resources = ["*"]
#   }
# }
#
# resource "aws_iam_role" "cluster_autoscaler" {
#   name = "${var.env}-eks-cluster-autoscaler-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "pods.eks.amazonaws.com"
#         }
#         Action = [
#           "sts:AssumeRole",
#           "sts:TagSession"
#         ]
#       }
#     ]
#   })
# }


# resource "aws_iam_policy" "cluster_autoscaler" {
#   name        = "${var.env}-cluster-autoscaler-policy"
#   description = "IAM policy for the Kubernetes cluster autoscaler"
#   policy      = data.aws_iam_policy_document.cluster_autoscaler.json
# }
#
#
# resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
#   role       = aws_iam_role.cluster_autoscaler.name
#   policy_arn = aws_iam_policy.cluster_autoscaler.arn
# }



resource "aws_iam_role_policy_attachment" "k8s-prometheus-ec2-read-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = aws_iam_role.k8s-prometheus.name
}


# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["${chomp(data.http.myip.response_body)}/32"]
  }



  tags = local.merged_tags

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
  tags = local.merged_tags
  depends_on = [aws_eks_cluster.this]
}

# Managed node groups — create one resource per entry in var.node_groups
resource "aws_eks_node_group" "node_groups" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-${each.key}-3"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = lookup(each.value, "desired", lookup(each.value, "min_nodes", 1))
    max_size     = lookup(each.value, "max_nodes", 2)
    min_size     = lookup(each.value, "min_nodes", 1)
  }

  instance_types = lookup(each.value, "instance_types", ["t3.medium"])
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")

  tags = merge(local.merged_tags, { "eks:nodegroup" = each.key })

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


resource "aws_eks_access_entry" "main" {
  for_each          = var.access
  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value["role"]
  # kubernetes_groups = each.value["kubernetes_groups"]
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

resource "aws_eks_pod_identity_association" "external-dns" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "default"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external-dns.arn
}

resource "aws_eks_pod_identity_association" "k8s-kubernetes" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "default"
  service_account = "kube-prom-stack-kube-prome-prometheus"
  role_arn        = aws_iam_role.k8s-prometheus.arn
}

# resource "aws_eks_pod_identity_association" "cluster-autoscaler" {
#   cluster_name    = aws_eks_cluster.this.name
#   namespace       = "kube-system"
#   service_account = "cluster-autoscaler-aws-cluster-autoscaler"
#   role_arn        = aws_iam_role.cluster_autoscaler.arn
# }
