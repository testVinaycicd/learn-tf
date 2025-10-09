

module "vpc" {
  source = "./modules/vpc"
  name = var.name
  cidr = var.vpc_cidr
  azs = var.azs
}

module "eks" {
  source = "./modules/eks"
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id = module.vpc.vpc_id
  access = var.access
  region = var.aws_region
  private_rt_ids = module.vpc.private_route_table_ids
}




module "addons" {
  source     = "./modules/addons"
  depends_on = [module.eks]      # ensures cluster exists before planning this module

}