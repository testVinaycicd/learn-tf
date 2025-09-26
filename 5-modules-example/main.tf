module "web-server-1" {
  source = "./modules/webapp"
  instance_type = var.instance_type
  name = "test-1-1-1-1"
}

