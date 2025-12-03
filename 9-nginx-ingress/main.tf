

module "vpc" {
  for_each    = var.vpc
  source      = "./modules/vpc"
  vpc_cidr    = each.value["cidr"]
  name        = each.key
  env         = var.env
  subnets     = each.value["subnets"]
  default_vpc = var.default_vpc

}

# module "eks" {
#   for_each    = var.eks
#   source      = "./modules/eks"
#   env         = var.env
#   eks_version = each.value["eks_version"]
#   node_groups = each.value["node_groups"]
#   addons      = each.value["addons"]
#   access      = each.value["access"]
#   subnet_ids  = module.vpc["main"].subnets["app"]
#   kms_arn     = var.kms_arn
# }

module "eks" {
  for_each    = var.eks
  source      = "./modules/eks-test"
  env         = var.env
  eks_version = each.value["eks_version"]
  node_groups = each.value["node_groups"]
  addons      = each.value["addons"]
  access      = each.value["access"]
  subnet_ids  = module.vpc["main"].subnets["app"]
  vault_token = var.vault_token
}


# module "addons" {
#   source     = "./modules/addons"
#   depends_on = [module.eks]      # ensures cluster exists before planning this module
#   vault_token = var.vault_token
#
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

# module "redis" {
#   source = "./modules/redis"
#   engine = ""
#   subnet_ids = [module.vpc["main"].subnet_ids["db-subnet-1"],module.vpc["main"].subnet_ids["db-subnet-2"],]
# }

output "vpc_subnet_id" {
  value = [module.vpc["main"].subnet_ids["db-subnet-1"],module.vpc["main"].subnet_ids["db-subnet-2"]]
}