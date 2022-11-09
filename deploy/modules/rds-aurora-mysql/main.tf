terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.region
}

resource "aws_db_subnet_group" "rds_db_sg" {
  name       = "${var.cluster_identifier}-db-subnet-group"
  subnet_ids = var.rds_subnet_ids
  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_rds_cluster_parameter_group" "impv_rds_db_pg" {
  name        = "${var.cluster_identifier}-pg"
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
  depends_on                        = [aws_rds_cluster_parameter_group.impv_rds_db_pg,aws_db_subnet_group.rds_db_sg]
  db_subnet_group_name              = aws_db_subnet_group.rds_db_sg.name
  cluster_identifier                = var.cluster_identifier
  engine                            = "aurora-mysql"
  master_username                   = var.master_username
  master_password                   = var.master_password
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.impv_rds_db_pg.name
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  skip_final_snapshot  = true
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

