resource "aws_rds_cluster" "wordpress" {
  cluster_identifier     = "wordpress-cluster"
  engine                 = "aurora-mysql"
  engine_version         = "5.7.mysql_aurora.2.10.1"
  availability_zones     = data.aws_availability_zones.zones
  database_name          = aws_ssm_parameter.dbname
  master_username        = aws_ssm_parameter.dbuser
  master_password        = aws_ssm_parameter.dbpassword
  db_subnet_group_name   = aws_subnet.db_subnet.id
  engine_mode            = "serverless"
  vpc_security_group_ids = [aws_security_group.rds_securitygroup.id]

  scaling_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  tags = local.tags


}


resource "aws_ssm_parameter" "dbname" {
  name  = "/app/wordpress/DATABASE_NAME"
  type  = "String"
  value = var.database_name
}

resource "aws_ssm_parameter" "dbuser" {
  name  = "/app/wordpress/DATABASE_USER"
  type  = "String"
  value = var.database_user_name
}

resource "aws_ssm_parameter" "dbpassword" {
  name  = "/app/wordpress/DATABASE_PASSWORD"
  type  = "SecureString"
  value = random_password.password
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_subnet" "db_subnet" {
  name        = "wordpress_cluster_subnet"
  description = "Subnet for the DB "
  subnet_ids  = data.aws_subnet_ids.subnets.subnets_ids
  tags        = local.tags
}

resource "aws_security_group" "rds_securitygroup" {
  name        = "RDS rules Wordpress"
  description = "RDS Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "3306 port RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  tags = local.tags

}

resource "aws_instance" "wordpress" {
  ami                         = data.aws_ami_ids.ubuntu.id
  instance_type               = var.ec2_instance_type
  associate_public_ip_address = true
  subnet_id                   = sort(data.aws_subnet_ids.subnets.ids)[0]
  security_groups             = aws_security_group.ec2_securitygroup.id
  key_name                    = local.key_name
  //iam_instance_profile = "my-profile"
  tags = merge(local.tags, {
    Name = "wordpress-instances"
  })

}

resource "aws_security_group" "ec2_securitygroup" {
  name        = "EC2 rules Wordpress"
  description = "EC2 Security Group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    iterator = port
    for_each = var.wordpress_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }

  dynamic "egress" {
    iterator = port
    for_each = var.wordpress_egress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }

  tags = local.tags

}