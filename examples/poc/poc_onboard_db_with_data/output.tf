
output "mssql_db_details" {
  value = module.rds_mssql
}


#
#output "created_db_instance_db_name" {
#  value = aws_db_instance.db_instance.db_name
#}

#output "created_db_instance_id" {
#  value = aws_db_instance.db_instance.id
#}

#
#output "created_db_instance_resource_id" {
#  value = aws_db_instance.db_instance.resource_id
#}
#
#output "created_db_instance_name" {
#  value = aws_db_instance.db_instance.name
#}

#output "db_snapshot" {
#  value = data.aws_db_snapshot.db_snapshot
#  #  value = aws_db_instance.aurora_mysql.database_name
#}

#output "created_db_instance_name" {
#  value = aws_db_instance.db_instance.db_name
##  value = aws_db_instance.aurora_mysql.database_name
#}

#output "created_db_instance_snapshot_identifier" {
#  value = aws_rds_cluster.aurora_mysql.snapshot_identifier
#}