resource "aws_db_instance" "shipping" {
  identifier              = "shipping-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "t3.small"
  allocated_storage       = 10
  max_allocated_storage   = 15
  storage_type            = "gp3"
  db_subnet_group_name    = aws_db_subnet_group.mysql.name
  vpc_security_group_ids  = [aws_security_group.rds_mysql.id]
  multi_az                = false
  publicly_accessible     = false
  deletion_protection     = true
  skip_final_snapshot     = false
  backup_retention_period = 7
  db_name                 = "shipping"
  username                = "root"
  password                = "RoboShop@1"  # hardcoded for now
  port                    = 3306

  tags = {
    Name = "shipping-mysql-dev"
  }
}