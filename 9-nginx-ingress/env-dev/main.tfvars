
db_instances = {

  mongo = {
    ami_id           = "ami-09c813fb71547fc4f"
    instance_type    = "t3.small"
    root_volume_size = 20
    subnet_ref       = "db"
    port             = 27017
    app_cidr = {
      app-subnet-1 = "11.0.4.0/24"
      app-subnet-2 = "11.0.5.0/24"
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

redis = {
  # dev environment - low-cost, single AZ (not recommended for prod)
  name                     = "roboshop-redis-dev"
  automatic_failover_enabled = false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
  multi_az_enabled         = false
  engine                   = "redis"
  engine_version           = "7.0"
  port                     = 6379
  kms_key_id               = "974d6e02b7ddde3ad55eda70ca66e1787e8d38962e2ca511fa2d8fd4c8652bae"
  maintenance_window       = "sun:05:00-sun:07:00"
  node_type                = "cache.t4g.small"
  notification_topic_arn   = ""
  num_cache_clusters       = 1
  snapshot_retention_limit = 0
  snapshot_window          = "03:00-04:00"
  subnet_group_name        = "roboshop-redis-subnet-group"   # existing or will be created if create_subnet_group=true
  parameter_group_name     = null
  environment_name         = "dev"
  allow_security_group_ids = ["sg-0abcde12345f67890"]        # EKS worker node SG (replace)
  allow_cidrs              = ["11.0.5.0/24","11.0.4.0/24"]
  create_subnet_group      = false
  subnet_ids               = ["subnet-0123456789abcdef0","subnet-0fedcba9876543210"]
  vpc_id                   = ""

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

kms_arn = "arn:aws:kms:us-east-1:886436958775:key/1082b02e-aba2-4c65-9bfd-2799fcdd513f"


# aws_region = "us-east-1"
#
#
# name = "terraform-learning-1"

# access = {
#   workstation = {
#     role                    = "arn:aws:iam::886436958775:role/workstation-role"
#     policy_arn              = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#     access_scope_type       = "cluster"
#     access_scope_namespaces = []
#     kubernetes_groups       = []
#   }
#   github_runner = {
#     role                    = "arn:aws:iam::886436958775:role/github-runner-role"
#     policy_arn              = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#     access_scope_type       = "cluster"
#     access_scope_namespaces = []
#     kubernetes_groups       = []
#   }
# }


eks = {
  main = {
    eks_version = 1.32
    node_groups = {
      main = {
        min_nodes      = 1
        max_nodes      = 10
        instance_types = ["t3.medium"]
        capacity_type  = "ON_DEMAND"
      }
    }

    addons = {
      #metrics-server = {}
      eks-pod-identity-agent = {}
    }

    access = {
      workstation = {
        role                    = "arn:aws:iam::886436958775:role/workstation-role"
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