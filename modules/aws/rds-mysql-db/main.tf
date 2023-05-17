resource "random_password" "db_password" {
  length  = 15
  special = false
}

resource "random_pet" "db_id" {
}

locals {
  db_username             = var.username
  db_password             = length(var.password) > 0 ? var.password : random_password.db_password.result
  db_identifier           = length(var.identifier) > 0 ? var.identifier : "edsf-db-demo-${random_pet.db_id.id}"
  db_name                 = length(var.name) > 0 ? var.name : replace("edsf-db-demo-${random_pet.db_id.id}", "-", "_")
  cloudwatch_stream_names = ["audit", "error", "general", "slowquery"]
}

resource "aws_cloudwatch_log_group" "cloudwatch_streams" {
  for_each          = { for name in local.cloudwatch_stream_names : name => name }
  name              = "/aws/rds/instance/${local.db_identifier}/${each.value}"
  retention_in_days = 30
  tags = var.tags
}

resource "aws_db_subnet_group" "rds_db_sg" {
  name       = "${local.db_identifier}-db-subnet-group"
  subnet_ids = var.rds_subnet_ids
  tags = var.tags
}

resource "aws_db_option_group" "impv_rds_db_og" {
  name                     = replace("${local.db_identifier}-pg", "_", "-")
  option_group_description = "RDS DB option group"
  engine_name              = "mysql"
  major_engine_version     = "5.7"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT,QUERY,QUERY_DDL,QUERY_DML,QUERY_DCL,QUERY_DML_NO_SELECT"
    }
    option_settings {
      name  = "SERVER_AUDIT_EXCL_USERS"
      value = "rdsadmin"
    }
  }
  tags = var.tags
}

resource "aws_db_instance" "rds_db" {
  allocated_storage       = 10
  db_name                 = local.db_name
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t3.micro"
  username                = local.db_username
  password                = local.db_password
  option_group_name       = aws_db_option_group.impv_rds_db_og.name
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_mysql_access.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_db_sg.name
  identifier              = local.db_identifier
  publicly_accessible     = true
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = local.cloudwatch_stream_names
  tags = var.tags
  depends_on = [
    aws_cloudwatch_log_group.cloudwatch_streams
  ]
}

data "aws_subnet" "subnet" {
  id = var.rds_subnet_ids[0]
}

resource "aws_security_group" "rds_mysql_access" {
  description = "RDS MySQL Access"
  vpc_id      = data.aws_subnet.subnet.vpc_id
  tags = var.tags
}

resource "aws_security_group_rule" "rds_mysql_access_rule" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidrs
  security_group_id = aws_security_group.rds_mysql_access.id
}
