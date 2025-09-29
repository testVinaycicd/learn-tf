module "vpc" {
  source = "./modules/vpc"
  name = var.name
  cidr = var.vpc_cidr
  azs = var.azs
}

module "iam" {
  source = "./modules/iam"
  name = var.name
}


module "web_server_1" {
  source = "./modules/webapp"
  instance_type = var.instance_type
  name = "test-1-1-1-1"
  subnet_id = module.vpc.public_subnets[0]
  security_group = module.vpc.sg_ec2_id
  iam_instance_profile = module.iam.instance_profile_name

}

module "alb" {
  source = "./modules/alb"
  name = var.name
  subnets = module.vpc.public_subnets
  target_instance_ids = [module.web_server_1.public_ip]
  vpc_id = module.vpc.vpc_id
}

module "obs_web1" {
  source           = "./modules/cloudwatch"
  name             = "${var.name}-web1"
  ec2_instance_id  = module.web_server_1.public_ip
}