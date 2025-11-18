output "subnets" {
  #   value = [for k, v in var.subnets : aws_subnet.main[v.group].id]
  value = transpose({ for k, v in aws_subnet.main : v.id => [v.tags["group"]] })
}

output "vpc" {
  value = aws_vpc.main
}

output "vpc_id" {
  value = aws_vpc.main.id
}



output "private_route_table_ids" {
  value = [for k, v in var.subnets : aws_route_table.main[k].id if var.subnets[k].ngw]
}

output "private_subnet_ids" {
  value = [for k, v in var.subnets : aws_subnet.main[k].id if var.subnets[k].ngw]
}



