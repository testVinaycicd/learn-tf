terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
  }



  backend "s3" {

  }


}


provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")

}

provider "helm" {
  kubernetes = {
    config_path = pathexpand("~/.kube/config")
  }
}

provider "aws" {
  region = var.aws_region
}



