
output "db_username" {
  value = local.db_username
}

output "db_password" {
  value = local.db_password
}

output "db_name" {
  value = local.db_name
}

output "db_identifier" {
  value = local.db_identifier
}

output "db_endpoint" {
  value = aws_rds_cluster.rds_db.endpoint
}

output "db_arn" {
  value = aws_rds_cluster.rds_db.arn
}

output "db_engine" {
  value = aws_rds_cluster.rds_db.engine
}

output "db_port" {
  value = aws_rds_cluster.rds_db.port
}

output "sql_cmd" {
  value = "mysql -h${aws_rds_cluster.rds_db.endpoint} --user ${local.db_username} mysql --password=${local.db_password}"
}

