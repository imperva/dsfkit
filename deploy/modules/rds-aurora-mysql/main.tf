resource "random_password" "db_password" {
  length  = 15
  special = false
}

resource "random_pet" "db_id" {
}

locals {
  db_username   = var.username
  db_password   = length(var.password) > 0 ? var.password : random_password.db_password.result
  db_identifier = length(var.identifier) > 0 ? var.identifier : "edsf-db-demo-${random_pet.db_id.id}"
  db_name       = length(var.name) > 0 ? var.name : replace("edsf-db-demo-${random_pet.db_id.id}", "-", "_")
}

resource "aws_db_subnet_group" "rds_db_sg" {
  name       = "${local.db_identifier}-db-subnet-group"
  subnet_ids = var.rds_subnet_ids
}

resource "aws_rds_cluster_parameter_group" "impv_rds_db_pg" {
  name        = "${local.db_identifier}-pg"
  family      = "aurora-mysql5.7"
  description = "RDS default cluster parameter group"
  parameter {
    name  = "server_audit_logging"
    value = 1
  }
  parameter {
    name  = "server_audit_excl_users"
    value = "rdsadmin"
  }
  parameter {
    name  = "server_audit_events"
    value = "CONNECT,QUERY,QUERY_DCL,QUERY_DDL,QUERY_DML,TABLE"
  }
}

resource "aws_rds_cluster" "rds_db" {
  db_subnet_group_name            = aws_db_subnet_group.rds_db_sg.name
  cluster_identifier              = local.db_identifier
  database_name                   = local.db_name
  engine                          = "aurora-mysql"
  master_username                 = local.db_username
  master_password                 = local.db_password
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.impv_rds_db_pg.name
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  skip_final_snapshot             = true
}

resource "aws_cloudwatch_log_group" "audit" {
  name = "/aws/rds/cluster/${aws_rds_cluster.rds_db.cluster_identifier}/audit"
}
resource "aws_cloudwatch_log_group" "error" {
  name = "/aws/rds/cluster/${aws_rds_cluster.rds_db.cluster_identifier}/error"
}
resource "aws_cloudwatch_log_group" "general" {
  name = "/aws/rds/cluster/${aws_rds_cluster.rds_db.cluster_identifier}/general"
}
resource "aws_cloudwatch_log_group" "slowquery" {
  name = "/aws/rds/cluster/${aws_rds_cluster.rds_db.cluster_identifier}/slowquery"
}

