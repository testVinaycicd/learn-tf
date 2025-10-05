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
    region       = "us-east-2"
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

  # vpc_config {
  #   # Use **public subnets** for level-1 to avoid NAT complexity
  #   subnet_ids              = var.subnet_ids
  #   endpoint_private_access = true
  #   endpoint_public_access  = true
  #   public_access_cidrs     = var.public_access_cidrs
  # }
  ###################
  # level 4
  ###################
  vpc_config {
    subnet_ids               = var.private_subnet_ids
    endpoint_private_access  = true
    endpoint_public_access   = true
    public_access_cidrs      = ["3.85.169.228/32"]
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
    desired_size = 1
    min_size     = 1
    max_size     = 2
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

  #######################################
  # level 2
  #######################################


}

#######################################
# level 2
#######################################

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


###############################################
# Transit Gateway
###############################################
resource "aws_ec2_transit_gateway" "main" {
  description = "Main TGW to connect default and EKS VPCs"
  amazon_side_asn = 64512
  auto_accept_shared_attachments = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  tags = { Name = "mikey-tgw" }
}

###############################################
# Attach Default VPC (172.31/16)
###############################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "default_vpc" {
  subnet_ids         = slice(data.aws_subnets.default.ids, 0, 2)
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = data.aws_vpc.default.id
  tags = { Name = "default-vpc-attachment" }
}

###############################################
# Attach EKS VPC (10.0/16)
###############################################
resource "aws_ec2_transit_gateway_vpc_attachment" "eks_vpc" {
  subnet_ids         = slice(var.private_subnet_ids, 0, 2)
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.vpc_id
  tags = { Name = "eks-vpc-attachment" }
}

###############################################
# Add TGW routes to both sides
###############################################

# Default VPC route table: route to 10.0.0.0/16 via TGW
resource "aws_route" "default_to_eks" {
  route_table_id         = data.aws_vpc.default.main_route_table_id
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}

data "aws_route_tables" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"] # matches anything with 'private' in the Name tag
  }
}

# EKS VPC private route table: route to 172.31.0.0/16 via TGW
# Adjust if you have multiple private route tables
resource "aws_route" "eks_to_default" {
  for_each = toset(data.aws_route_tables.private.ids)
  route_table_id         = each.value
  destination_cidr_block = "172.31.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}

# All subnets in default VPC
data "aws_subnets" "default_all" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# For each subnet, fetch the route table actually associated
data "aws_route_table" "default_by_subnet" {
  for_each  = toset(data.aws_subnets.default_all.ids)
  subnet_id = each.key
}

# Ensure every associated RT can reach 10.0.0.0/16 via TGW
resource "aws_route" "default_to_eks_all" {
  for_each               = data.aws_route_table.default_by_subnet
  route_table_id         = each.value.id
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}


resource "aws_security_group_rule" "kubectl_to_eks_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  source_security_group_id = "sg-0dcda09f65953b6b7"
  description              = "Default VPC EC2 -> EKS API over TGW"
  depends_on               = [aws_eks_cluster.this]
}

# -------- Shared: dynamic VPC CIDRs --------
data "aws_vpc" "eks"     { id = var.vpc_id }
data "aws_vpc" "def"     { id = data.aws_vpc.default.id }

# -------- Security groups for DNS (TCP/UDP 53) --------
resource "aws_security_group" "dns_inbound" {
  name        = "${var.cluster_name}-dns-inbound-sg"
  description = "Allow DNS from default VPC to inbound resolver in EKS VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port=53
    to_port=53
    protocol="tcp"
    cidr_blocks=[data.aws_vpc.def.cidr_block]
  }
  ingress {
    from_port=53
    to_port=53
    protocol="udp"
    cidr_blocks=[data.aws_vpc.def.cidr_block]
  }
  egress  {
    from_port=0
    to_port=0
    protocol="-1"
    cidr_blocks=["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dns_outbound" {
  name        = "default-dns-outbound-sg"
  description = "Allow default VPC subnets to reach outbound resolver"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port=53
    to_port=53
    protocol="tcp"
    cidr_blocks=[data.aws_vpc.default.cidr_block]
  }
  ingress {
    from_port=53
    to_port=53
    protocol="udp"
    cidr_blocks=[data.aws_vpc.default.cidr_block]
  }
  egress  {
    from_port=0
    to_port=0
    protocol="-1"
    cidr_blocks=["0.0.0.0/0"]
  }
}

# -------- INBOUND resolver endpoint in the EKS VPC --------
# Use two private subnets from your EKS VPC
resource "aws_route53_resolver_endpoint" "inbound_eks" {
  name               = "${var.cluster_name}-inbound"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.dns_inbound.id]

  ip_addresses { subnet_id = var.private_subnet_ids[0] }
  ip_addresses { subnet_id = var.private_subnet_ids[1] }

  tags = { Name = "${var.cluster_name}-inbound" }
}

# -------- OUTBOUND resolver endpoint in the default VPC --------
# Use two subnets from the default VPC
resource "aws_route53_resolver_endpoint" "outbound_default" {
  name               = "default-outbound"
  direction          = "OUTBOUND"
  security_group_ids = [aws_security_group.dns_outbound.id]

  ip_addresses { subnet_id = data.aws_subnets.default.ids[0] }
  ip_addresses { subnet_id = data.aws_subnets.default.ids[1] }

  tags = { Name = "default-outbound" }
}

# Helper locals to capture the private IPs of the inbound endpoint
locals {
  inbound_ips = [
    for ip in aws_route53_resolver_endpoint.inbound_eks.ip_addresses : ip.ip
  ]
}

# -------- Forward rule in default VPC to EKS inbound endpoint --------
# Forward the EKS private endpoint zone to the EKS VPC.
# Using the regional zone covers EKS endpoints: <hash>.<suffix>.us-east-2.eks.amazonaws.com
resource "aws_route53_resolver_rule" "forward_eks" {
  domain_name          = "us-east-2.eks.amazonaws.com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound_default.id

  dynamic "target_ip" {
    for_each = local.inbound_ips
    content {
      ip = target_ip.value
    }
  }

  name = "forward-eks-us-east-2"
}

# Associate the rule with the default VPC so instances there use it
resource "aws_route53_resolver_rule_association" "default_assoc" {
  resolver_rule_id = aws_route53_resolver_rule.forward_eks.id
  vpc_id           = data.aws_vpc.default.id
}
