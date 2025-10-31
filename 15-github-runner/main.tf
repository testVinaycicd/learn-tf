terraform {
  backend "s3" {
    bucket = "learning-bucket-307"    # existing bucket
    key          = "terraform-module/github-runner/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}



## github runer

module "tool-infra" {
  for_each = var.tools
  source = "./modules"
  ami_id = var.ami_id
  instance_type = each.value["instance_type"]
  name = each.key
  port = each.value["port"]
  zone_id = var.zone_id
  iam_policy = each.value["iam_policy"]
  root_block_device = each.value["root_block_device"]
}
