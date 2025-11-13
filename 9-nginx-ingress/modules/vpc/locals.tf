locals {
  public_route_table_ids  = [for k, v in var.subnets : aws_route_table.main[k].id if var.subnets[k].igw]
  public_subnet_ids       = [for k, v in var.subnets : aws_subnet.main[k].id if var.subnets[k].igw]
  private_route_table_ids = [for k, v in var.subnets : aws_route_table.main[k].id if var.subnets[k].ngw]
  private_subnet_ids      = [for k, v in var.subnets : aws_subnet.main[k].id if var.subnets[k].ngw]
  all_route_table_ids     = [for k, v in var.subnets : aws_route_table.main[k].id]
  all_subnet_ids          = [for k, v in var.subnets : aws_subnet.main[k].id]
}