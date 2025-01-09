resource "random_password" "db_password" {
  length  = 15
  special = false
}

resource "random_pet" "db_id" {
}

locals {
  db_username             = var.username
  db_password             = length(var.password) > 0 ? var.password : random_password.db_password.result
  db_identifier           = length(var.identifier) > 0 ? var.identifier : join("-", [var.name_prefix, random_pet.db_id.id])
  db_name                 = length(var.name) > 0 ? var.name : replace(join("-", [var.name_prefix, random_pet.db_id.id]), "-", "_")
  cloudwatch_stream_names = ["postgresql"]
}

resource "aws_cloudwatch_log_group" "cloudwatch_streams" {
  for_each          = { for name in local.cloudwatch_stream_names : name => name }
  name              = "/aws/rds/instance/${local.db_identifier}/${each.value}"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_db_subnet_group" "rds_db_sg" {
  name       = "${local.db_identifier}-db-subnet-group"
  subnet_ids = var.rds_subnet_ids
  tags       = var.tags
}

resource "aws_db_parameter_group" "postgres15_audit" {
  name        = "${local.db_identifier}-postgres15-audit-pg"
  family      = "postgres15"
  description = "Custom parameter group for Postgres"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pgaudit"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "pgaudit.role"
    value        = "rds_pgaudit"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_disconnections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_error_verbosity"
    value        = "verbose"
    apply_method = "immediate"
  }

  parameter {
    name         = "pgaudit.log"
    value        = "all"
    apply_method = "pending-reboot"
  }

  tags = var.tags
}


resource "aws_db_instance" "rds_db" {
  allocated_storage       = 10
  db_name                 = local.db_name
  engine                  = "postgres"
  engine_version          = "15.10"
  instance_class          = "db.m5.large"
  username                = local.db_username
  password                = local.db_password
  parameter_group_name    = aws_db_parameter_group.postgres15_audit.name
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_postgres_access.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_db_sg.name
  identifier              = local.db_identifier
  publicly_accessible     = true
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = local.cloudwatch_stream_names
  tags                            = var.tags
  depends_on = [
    aws_cloudwatch_log_group.cloudwatch_streams
  ]
}

data "aws_subnet" "subnet" {
  id = var.rds_subnet_ids[0]
}

resource "aws_security_group" "rds_postgres_access" {
  description = "RDS PostgreSQL Access"
  vpc_id      = data.aws_subnet.subnet.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "rds_postgres_access_rule" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidrs
  security_group_id = aws_security_group.rds_postgres_access.id
}
