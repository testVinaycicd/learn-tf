resource "aws_eks_pod_identity_association" "external-dns" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external-dns.arn
}
