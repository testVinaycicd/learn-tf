output "cluster_name"   { value = aws_eks_cluster.this.name }
output "cluster_arn"    { value = aws_eks_cluster.this.arn }
output "cluster_status" { value = aws_eks_cluster.this.status }