
db_instances = {

  mongo = {
    ami_id           = "ami-09c813fb71547fc4f"
    instance_type    = "t3.small"
    root_volume_size = 20
    subnet_ref       = "db"
    port             = 27017
    app_cidr = {
      app-subnet-1 = "11.200.4.0/24"
      app-subnet-2 = "11.200.5.0/24"
    }
  }
  # redis = {
  #   ami_id           = "ami-09c813fb71547fc4f"
  #   instance_type    = "t3.small"
  #   root_volume_size = 20
  #   subnet_ref       = "db"
  #   port             = 6379
  #   app_cidr = {
  #     app-subnet-1 = "10.200.4.0/24"
  #     app-subnet-2 = "10.200.5.0/24"
  #   }
  # }
  #
  # mysql = {
  #   ami_id           = "ami-09c813fb71547fc4f"
  #   instance_type    = "t3.small"
  #   root_volume_size = 20
  #   subnet_ref       = "db"
  #   port             = 3306
  #   app_cidr = {
  #     app-subnet-1 = "10.200.4.0/24"
  #     app-subnet-2 = "10.200.5.0/24"
  #   }
  # }
  # rabbitmq = {
  #   ami_id           = "ami-09c813fb71547fc4f"
  #   instance_type    = "t3.small"
  #   root_volume_size = 20
  #   subnet_ref       = "db"
  #   port             = 5672
  #   app_cidr = {
  #     app-subnet-1 = "10.200.4.0/24"
  #     app-subnet-2 = "10.200.5.0/24"
  #   }
  # }

}

zone_id                = "Z09180393TY9K7UQDKE5E"
# vpc_security_group_ids = ["sg-0ea2a448676b70f53"]
env                    = "dev"



vpc = {
  main = {
    cidr = "11.0.0.0/16"
    subnets = {
      public-subnet-1 = {
        cidr  = "11.0.0.0/24"
        igw   = true
        ngw   = false
        zone  = "us-east-1a"
        group = "public"
      }
      public-subnet-2 = {
        cidr  = "11.0.1.0/24"
        igw   = true
        ngw   = false
        zone  = "us-east-1b"
        group = "public"
      }
      db-subnet-1 = {
        cidr  = "11.0.2.0/24"
        igw   = false
        ngw   = true
        zone  = "us-east-1a"
        group = "db"
      }
      db-subnet-2 = {
        cidr  = "11.0.3.0/24"
        igw   = false
        ngw   = true
        zone  = "us-east-1b"
        group = "db"
      }
      app-subnet-1 = {
        cidr  = "11.0.4.0/24"
        igw   = false
        ngw   = true
        zone  = "us-east-1a"
        group = "app"
      }
      app-subnet-2 = {
        cidr  = "11.0.5.0/24"
        igw   = false
        ngw   = true
        zone  = "us-east-1b"
        group = "app"
      }
    }
  }
}

default_vpc = {
  vpc_id        = "vpc-017f037b7406e731c"
  vpc_cidr      = "172.31.0.0/16"
  routetable_id = "rtb-0c6ae129f078993f1"
}

bastion_ssh_nodes = {
  workstation   = "172.31.16.221/32"
  # github_runner = "172.31.2.181/32"
}

kms_arn = "arn:aws:kms:us-east-1:886436958775:key/6ba51f0e-e1f1-459f-a102-3eff3402117b"


aws_region = "us-east-1"


name = "terraform-learning-1"

access = {
  workstation = {
    role                    = "arn:aws:iam::633788536644:role/workstation-role"
    policy_arn              = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope_type       = "cluster"
    access_scope_namespaces = []
    kubernetes_groups       = []
  }
  github_runner = {
    role                    = "arn:aws:iam::886436958775:role/github-runner-role"
    policy_arn              = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope_type       = "cluster"
    access_scope_namespaces = []
    kubernetes_groups       = []
  }
}


eks = {
  main = {
    eks_version = 1.32
    node_groups = {
      main = {
        min_nodes      = 1
        max_nodes      = 10
        instance_types = ["t3.medium"]
        capacity_type  = "SPOT"
      }
    }

    addons = {
      #metrics-server = {}
      eks-pod-identity-agent = {}
    }

    access = {
      workstation = {
        role                    = "arn:aws:iam::633788536644:role/workstation-role"
        policy_arn              = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope_type       = "cluster"
        access_scope_namespaces = []
      }
      github_runner = {
        role                    = "arn:aws:iam::886436958775:role/github-runner-role"
        policy_arn              = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope_type       = "cluster"
        access_scope_namespaces = []
      }
    }

  }
}