/*
output "mssql_db_details" {
  value = {
    db_arn            = try(aws_db_instance.rds_db.arn, null)
    db_endpoint       = try(aws_db_instance.rds_db.endpoint, null)
    db_engine         = try(aws_db_instance.rds_db.engine, null)
    db_identifier     = try(aws_db_instance.rds_db.identifier, null)
    db_name           = try(aws_db_instance.rds_db.identifier, null)
    db_password       = try(nonsensitive(aws_db_instance.rds_db.password), null)
    db_port           = try(aws_db_instance.rds_db.port, null)
    db_username       = try(aws_db_instance.rds_db.username, null)
    db_url            = try(aws_db_instance.rds_db.address, null)

#    todo - change!
#    sql_cmd           = "mysql -h${aws_db_instance.rds_db.address} --user ${local.db_username} mysql --password=${nonsensitive(local.db_password)}"

#    public_subnets  = try(module.vpc.public_subnets, null)
#    private_subnets = try(module.vpc.private_subnets, null)
  }
}*/

output "iam_role" {
  value = local.role_arn
}

output "sql_scripts_s3_bucket" {
  value = aws_s3_bucket.mssql_lambda_bucket.bucket
}

/*
output "mssql_iam_role_arn" {
  value = data.aws_iam_role.lambda_mssql_assignee_role.arn
}

output "mssql_infra_lambda_name" {
  value = aws_lambda_function.lambda_mssql_infra.function_name
}

output "rds_subnet_ids" {
  value = aws_db_subnet_group.rds_db_sg
}
*/

#output "lambda_result_entry" {
#  value = jsondecode(aws_lambda_invocation.mssql_infra_invocation.result)
#}



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

#output "sql_cmd" {
#  value = "mysql -h${aws_db_instance.rds_db.address} --user ${local.db_username} mysql --password=${nonsensitive(local.db_password)}"
#}
