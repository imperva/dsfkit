output "db_username" {
  value = local.db_username
}

output "db_password" {
  value = random_password.db_password.result
}

output "db_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}

output "db_arn" {
  value = aws_db_instance.rds_instance.arn
}
