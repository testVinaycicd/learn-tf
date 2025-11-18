# ###############################################
# # Transit Gateway
# ###############################################
# resource "aws_ec2_transit_gateway" "main" {
#   description = "Main TGW to connect default and EKS VPCs"
#   amazon_side_asn = 64512
#   auto_accept_shared_attachments = "enable"
#   default_route_table_association = "enable"
#   default_route_table_propagation = "enable"
#   tags = { Name = "mikey-tgw" }
# }
#
# ###############################################
# # Attach Default VPC (172.31/16)
# ###############################################
# data "aws_vpc" "default" {
#   default = true
# }
#
# data "aws_subnets" "default" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.default.id]
#   }
# }
#
# resource "aws_ec2_transit_gateway_vpc_attachment" "default_vpc" {
#   subnet_ids         = slice(data.aws_subnets.default.ids, 0, 2)
#   transit_gateway_id = aws_ec2_transit_gateway.main.id
#   vpc_id             = data.aws_vpc.default.id
#   tags = { Name = "default-vpc-attachment" }
# }
#
# ###############################################
# # Attach EKS VPC (10.0/16)
# ###############################################
# resource "aws_ec2_transit_gateway_vpc_attachment" "eks_vpc" {
#   subnet_ids         = slice(var.private_subnet_ids, 0, 2)
#   transit_gateway_id = aws_ec2_transit_gateway.main.id
#   vpc_id             = var.vpc_id
#   tags = { Name = "eks-vpc-attachment" }
# }
#
# data "aws_route_tables" "private" {
#   filter {
#     name   = "vpc-id"
#     values = [var.vpc_id]
#   }
#
#   filter {
#     name   = "tag:Name"
#     values = ["*private*"] # matches anything with 'private' in the Name tag
#   }
# }
#
# # EKS VPC private route table: route to 172.31.0.0/16 via TGW
# # Adjust if you have multiple private route tables
# resource "aws_route" "eks_to_default" {
#
#   for_each = var.private_rt_ids
#   route_table_id         = each.value
#   destination_cidr_block = "172.31.0.0/16"
#   transit_gateway_id     = aws_ec2_transit_gateway.main.id
# }
#
# # # All subnets in default VPC
# # data "aws_subnets" "default_all" {
# #   filter {
# #     name = "vpc-id"
# #     values = [data.aws_vpc.default.id]
# #   }
# # }
#
# # For each subnet, fetch the route table actually associated
# data "aws_route_tables" "default_non_main" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.default.id]
#   }
#   # exclude the main table
#   filter {
#     name   = "association.main"
#     values = ["false"]
#   }
# }
#
# # Build the complete set: main RT + all non-main RTs
# locals {
#   default_vpc_route_table_ids = toset(
#     concat(
#       [data.aws_vpc.default.main_route_table_id],
#       data.aws_route_tables.default_non_main.ids
#     )
#   )
# }
#
#
#
# # Ensure EVERY default-VPC route table can reach the EKS CIDR via TGW
# resource "aws_route" "default_to_eks_all" {
#   for_each               = local.default_vpc_route_table_ids
#   route_table_id         = each.value
#   destination_cidr_block = data.aws_vpc.eks.cidr_block                # EKS VPC CIDR
#   transit_gateway_id     = aws_ec2_transit_gateway.main.id
# }
#
#
# # -------- INBOUND resolver endpoint in the EKS VPC --------
# # Use two private subnets from your EKS VPC
# resource "aws_route53_resolver_endpoint" "inbound_eks" {
#   name               = "${var.cluster_name}-inbound"
#   direction          = "INBOUND"
#   security_group_ids = [aws_security_group.dns_inbound.id]
#
#   ip_address { subnet_id = var.private_subnet_ids[0] }
#   ip_address { subnet_id = var.private_subnet_ids[1] }
# }
#
# resource "aws_route53_resolver_endpoint" "outbound_default" {
#   name               = "default-outbound"
#   direction          = "OUTBOUND"
#   security_group_ids = [aws_security_group.dns_outbound.id]
#
#   ip_address { subnet_id = data.aws_subnets.default.ids[0] }
#   ip_address { subnet_id = data.aws_subnets.default.ids[1] }
# }
#
# # Helper locals to capture the private IPs of the inbound endpoint
# locals {
#   inbound_ips = [
#     for ip in aws_route53_resolver_endpoint.inbound_eks.ip_address : ip.ip
#   ]
# }
#
# locals {
#   # From "https://…hash….<suffix>.<region>.eks.amazonaws.com" → "<suffix>.<region>.eks.amazonaws.com"
#   eks_private_domain = join(".", slice(split(".", trimprefix(aws_eks_cluster.this.endpoint, "https://")), 1, 4))
# }
#
# # -------- Forward rule in default VPC to EKS inbound endpoint --------
# # Forward the EKS private endpoint zone to the EKS VPC.
# # Using the regional zone covers EKS endpoints: <hash>.<suffix>.us-east-2.eks.amazonaws.com
# resource "aws_route53_resolver_rule" "forward_eks" {
#   domain_name          = local.eks_private_domain
#   rule_type            = "FORWARD"
#   resolver_endpoint_id = aws_route53_resolver_endpoint.outbound_default.id
#
#   dynamic "target_ip" {
#     for_each = local.inbound_ips
#     content {
#       ip = target_ip.value
#     }
#   }
#
#   name = "forward-eks-us-east-2"
# }
#
# # Associate the rule with the default VPC so instances there use it
# resource "aws_route53_resolver_rule_association" "default_assoc" {
#   resolver_rule_id = aws_route53_resolver_rule.forward_eks.id
#   vpc_id           = data.aws_vpc.default.id
# }
