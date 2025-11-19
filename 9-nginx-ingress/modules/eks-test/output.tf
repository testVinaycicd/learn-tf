output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_group_names" {
  value = [for ng in aws_eks_node_group.node_groups : ng.node_group_name]
}

output "kubeconfig_command_note" {
  value = "Run: aws eks  update-kubeconfig --name ${aws_eks_cluster.this.name}"
}
