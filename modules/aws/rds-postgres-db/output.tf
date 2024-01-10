
output "db_username" {
  value = local.db_username
}

output "db_password" {
  value = nonsensitive(local.db_password)
}

output "db_name" {
  value = local.db_name
}

output "db_identifier" {
  value = local.db_identifier
}

output "db_address" {
  value = aws_db_instance.rds_db.address
}

output "db_endpoint" {
  value = aws_db_instance.rds_db.endpoint
}

output "db_arn" {
  value = aws_db_instance.rds_db.arn
}

output "db_engine" {
  value = aws_db_instance.rds_db.engine
}

output "db_port" {
  value = aws_db_instance.rds_db.port
}

output "sql_cmd" {
  value = "PGPASSWORD='${nonsensitive(local.db_password)}' psql -h${aws_db_instance.rds_db.address} -U${local.db_username} postgres"
}



