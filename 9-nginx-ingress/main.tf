

module "vpc" {
  for_each    = var.vpc
  source      = "./modules/vpc"
  vpc_cidr    = each.value["cidr"]
  name        = each.key
  env         = var.env
  subnets     = each.value["subnets"]
  default_vpc = var.default_vpc

}
module "eks" {
  source = "./modules/eks"
  private_subnet_ids = module.vpc["main"].private_subnet_ids
  vpc_id = module.vpc["main"].vpc_id
  access = var.access
  region = var.aws_region
  private_rt_ids = module.vpc["main"].private_route_table_ids
  addons = var.addons
}




# module "addons" {
#   source     = "./modules/addons"
#   depends_on = [module.eks]      # ensures cluster exists before planning this module
#   vault_token = var.vault_token
# }

# module "mysql" {
#   source  = "modules/mysql"
#   depends_on = [module.vpc]
#   vpc_id = module.vpc.vpc_id
#   # eks_nodes_sg_id = module.eks.eks_sg_id
#   private_subnet_ids = module.vpc.private_subnet_ids
#
# }

module "mongodb" {
  for_each = var.db_instances
  source  = "./modules/dbs"
  depends_on = [module.vpc]

  ami_id = each.value["ami_id"]
  env = var.env
  instance_type = each.value["instance_type"]
  name = each.key
  zone_id = var.zone_id
  vault_token = var.vault_token
  ansible_role = lookup(each.value,"ansible_role",each.key )
  root_volume_size = each.value["root_volume_size"]
  subnet_ids =  module.vpc["main"].subnets["db"]
  vpc_id = module.vpc["main"].vpc["id"]
  bastion_ssh_nodes = var.bastion_ssh_nodes
  app_cidr = each.value["app_cidr"]
  port = each.value["port"]
  kms_arn = var.kms_arn

  # vpc_id = module.vpc.vpc_id
  # eks_nodes_sg_id = module.eks.eks_sg_id
  # private_subnet_ids = module.vpc.private_subnet_ids

}