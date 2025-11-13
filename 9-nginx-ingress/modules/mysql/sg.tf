resource "aws_db_subnet_group" "mysql" {
  name       = "rds-mysql-private"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "mysql-subnet-group"
  }
}

# --- security group ---
resource "aws_security_group" "rds_mysql" {
  name        = "rds-mysql-sg"
  description = "Allow MySQL from EKS app nodes"
  vpc_id      = var.vpc_id

  ingress {
    description      = "MySQL from EKS nodes"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [var.eks_nodes_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}