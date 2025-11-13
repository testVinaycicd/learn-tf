output "cluster_name"   { value = aws_eks_cluster.this.name }
output "cluster_arn"    { value = aws_eks_cluster.this.arn }
output "cluster_status" { value = aws_eks_cluster.this.status }
output "eks_sg_id" { value = aws_security_group.nodes.id }

