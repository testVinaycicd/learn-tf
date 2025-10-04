terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
  backend "s3" {
    bucket = "learning-bucket-307"    # existing bucket
    key          = "terraform-module/test/terraform-eks.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
provider "aws" {
  region = "us-east-2"
}



# get partition wheere i am woring like aws or asw-cn(china) or aws-us-gov
data "aws_partition" "current" {}

#  returns who am i  ie account_id,user_id,arn


# store and manages encryption key in aws
#  when ever in kubernetes you want to encrypt or decrypt some data you ask kms to do it with your keys
resource "aws_kms_key" "eks" {
  description = "${var.cluster_name}-eks-secrets-CMK"
  deletion_window_in_days = 7
  enable_key_rotation = true
  tags = var.tags
}

# creates a alias name rather than uuid
resource "aws_kms_alias" "eks" {
  name          = "alias/eks/${var.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks.id
}



resource "aws_security_group" "cluster" {
  name = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id = var.vpc_id
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = merge(var.tags, { Name = "${var.cluster_name}-cluster" })
}

resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes"
  description = "EKS nodes security group"
  vpc_id      = var.vpc_id

  # Allow nodes all egress to pull images, reach AWS APIs, etc.
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-nodes" })
}


# allows traffic on tpc 443 into the control plane but only if it comes from node sg the source
resource "aws_security_group_rule" "nodes_to_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id   # source
  description              = "Nodes to EKS API server"
}

############################
# IAM: EKS cluster role
############################
data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole","sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "eks" {
  name = "${var.cluster_name}-cluster-iam"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
  force_detach_policies = true
  tags = var.tags

}


# grants EKS control plane required permissions it needs for networking
# cloudwatchlogs
# elb/alb/nlb
# describe and interact with vpc subnets
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role = aws_iam_role.eks.id
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Allows eks to make use of kms for secret encryption
resource "aws_iam_policy" "eks_kms" {
  name   = "${var.cluster_name}-ClusterEncryption"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["kms:Encrypt","kms:Decrypt","kms:DescribeKey","kms:ListGrants"],
      Resource = aws_kms_key.eks.arn
    }]
  })
  tags = var.tags
}


resource "aws_iam_role_policy_attachment" "eks_kms" {
  role       = aws_iam_role.eks.name
  policy_arn = aws_iam_policy.eks_kms.arn
}


############################
# EKS cluster
############################

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks.arn
  version = var.kubernetes_version
  enabled_cluster_log_types = ["api","audit","authenticator","controllerManager","scheduler"]

  vpc_config {
    security_group_ids = [aws_security_group.cluster.id]
    subnet_ids = var.private_subnet_ids
    endpoint_private_access = var.endpoint_private_access # (whether the API server endpoint is accessible inside the VPC)
    endpoint_public_access = var.endpoint_public_access
    public_access_cidrs = var.endpoint_public_cidrs  # office ip or trusted ip (restrict which IP ranges can hit the public API endpoint.)
  }

  # IP address family for Kubernetes pod and service networking.
  kubernetes_network_config {
    ip_family = "ipv4"
  }

  # enables encryption at rest
  encryption_config {
    provider { key_arn = aws_kms_key.eks.arn }
    resources = ["secrets"]
  }

  # who gets admin access when the cluster is created.
  access_config {
    authentication_mode = "API" # tell eks to use iam for authentication
    bootstrap_cluster_creator_admin_permissions = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_kms
  ]

  tags = var.tags


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
  tags            = merge(var.tags, { Name = "${var.cluster_name}-irsa" })
  depends_on      = [aws_eks_cluster.this]
}

############################
# Access Entries (RBAC)
############################
# Give your admin role full cluster-admin
# who can access the cluster
# register this iam principle as someone who can access the cluster
resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.admin_principal_arn
  type          = "STANDARD"
  tags          = var.tags
}

# what level those users have access to that cluster
resource "aws_eks_access_policy_association" "admin" {
  cluster_name = aws_eks_cluster.this.name
  principal_arn = var.admin_principal_arn
  policy_arn   = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
  depends_on = [aws_eks_access_entry.admin]
}

############################
# Node group (managed)
############################
# Node IAM role
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
  name               = "${var.cluster_name}-nodes"
  assume_role_policy = data.aws_iam_policy_document.nodes_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "nodes_minimal" {
  for_each = {
    AmazonEKSWorkerNodeMinimalPolicy   = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
    AmazonEC2ContainerRegistryPullOnly = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  }
  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}


resource "aws_eks_node_group" "default" {
  cluster_name  = aws_eks_cluster.this.name
  node_role_arn = aws_iam_role.nodes.arn
  subnet_ids = var.private_subnet_ids
  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  ami_type  = "AL2_x86_64"
  capacity_type = "SPOT"

  update_config {
    max_unavailable = 1
  }

  tags = var.tags

  # may create ec2 instance but fail to attach permission that can lead to not ready state
  depends_on = [aws_iam_role_policy_attachment.nodes_minimal]


}


############################
# Core addons (pinned)
###########################S

data "aws_eks_addon_version" "core" {
  for_each = toset(["vpc-cni","kube-proxy","coredns"])
  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "core" {
  for_each     = data.aws_eks_addon_version.core
  cluster_name = aws_eks_cluster.this.name
  addon_name   = each.key
  addon_version = each.value.version
  tags         = var.tags
}






















