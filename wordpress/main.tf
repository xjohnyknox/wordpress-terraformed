resource "aws_rds_cluster" "wordpress" {
  cluster_identifier      = "wordpress-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.10.1"
  availability_zones      = data.aws_availability_zones.zones
  database_name           = aws_ssm_parameter.dbname
  master_username         = aws_ssm_parameter.dbuser
  master_password         = aws_ssm_parameter.dbpassword
  db_subnet_group_name = ""
  engine_mode = "serverless"
  vpc_security_group_ids = ""

  scaling_configuration {
    min_capacity = 1
    max_capacity = 2
  }

tags = local.tags


}


resource "aws_ssm_parameter" "dbname" {
  name        = "/app/wordpress/DATABASE_NAME"
  type        = "String"
  value       = var.database_name
}

resource "aws_ssm_parameter" "dbuser" {
  name        = "/app/wordpress/DATABASE_USER"
  type        = "String"
  value       = var.database_user_name
}

resource "aws_ssm_parameter" "dbpassword" {
  name        = "/app/wordpress/DATABASE_PASSWORD"
  type        = "SecureString"
  value       = random_password.password
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_subnet" "db_subnet" {
  name = "wordpress_cluster_subnet"  
  description = "Subnet for the DB "
  subnet_ids = data.aws_subnet_ids.subnets.subnets_ids
  tags = local.tags
}