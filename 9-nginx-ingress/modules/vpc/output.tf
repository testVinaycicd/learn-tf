output "subnets" {
  #   value = [for k, v in var.subnets : aws_subnet.main[v.group].id]
  value = transpose({ for k, v in aws_subnet.main : v.id => [v.tags["group"]] })
}

output "vpc" {
  value = aws_vpc.main
}