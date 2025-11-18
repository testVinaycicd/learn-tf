resource "aws_eks_cluster" "main" {
  name = var.env

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  role_arn = aws_iam_role.cluster-role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  # This is not needed for us as we dont use local secrets, We are using all secrets from vault.
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_arn
    }
  }
}

resource "aws_launch_template" "main" {
  for_each = var.node_groups
  name     = each.key

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      encrypted   = true
      kms_key_id  = var.kms_arn
    }
  }

}

resource "aws_eks_node_group" "main" {
  for_each        = var.node_groups
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node-role.arn
  subnet_ids      = var.subnet_ids
  instance_types  = each.value["instance_types"]
  capacity_type   = each.value["capacity_type"]

  launch_template {
    name    = aws_launch_template.main[each.key].name
    version = "$Latest"
  }

  scaling_config {
    desired_size = each.value["min_nodes"]
    max_size     = each.value["max_nodes"]
    min_size     = each.value["min_nodes"]
  }

  lifecycle {
    ignore_changes = [scaling_config]
  }

}


resource "aws_eks_addon" "addons" {
  for_each     = var.addons
  cluster_name = aws_eks_cluster.main.name
  addon_name   = each.key
}


resource "aws_eks_access_entry" "main" {
  for_each          = var.access
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = each.value["role"]
  kubernetes_groups = each.value["kubernetes_groups"]
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "main" {
  for_each      = var.access
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = each.value["policy_arn"]
  principal_arn = each.value["role"]

  access_scope {
    type       = each.value["access_scope_type"]
    namespaces = each.value["access_scope_namespaces"]
  }
}

resource "aws_eks_pod_identity_association" "external-dns" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "default"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external-dns.arn
}

resource "aws_eks_pod_identity_association" "k8s-kubernetes" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "default"
  service_account = "kube-prom-stack-kube-prome-prometheus"
  role_arn        = aws_iam_role.k8s-prometheus.arn
}

resource "aws_eks_pod_identity_association" "cluster-autoscaler" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler-aws-cluster-autoscaler"
  role_arn        = aws_iam_role.cluster-autoscaler.arn
}
