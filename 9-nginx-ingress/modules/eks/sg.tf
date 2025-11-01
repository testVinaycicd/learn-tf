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

resource "aws_security_group_rule" "allow_apiserver_to_nginx_webhook" {
  type                     = "ingress"
  description              = "Allow EKS control plane to reach ingress-nginx admission webhook"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  security_group_id        = aws_security_group.nodes.id

}

# transit gateway
resource "aws_security_group_rule" "kubectl_to_eks_api" {
  type              = "ingress" # or "ingress" depending on your TF version
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  cidr_blocks       = [data.aws_vpc.default.cidr_block]  # 172.31.0.0/16
  description       = "Default VPC EC2 to EKS API over TGW"
  depends_on        = [aws_eks_cluster.this]
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