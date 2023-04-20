output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_network_interface.eni.private_ip
}

output "private_dns" {
  description = "Private dns address of the instance"
  value       = aws_network_interface.eni.private_dns_name
}

output "display_name" {
  value = aws_instance.agent.tags["Name"]
}

output "ssh_user" {
  value = local.ami_ssh_user
}

output "instance_id" {
  value = aws_instance.agent.id
}

output "db_type" {
  value = var.db_type
}

# output "db_username" {
#   value = local.db_username
# }

# output "db_password" {
#   value = nonsensitive(local.db_password)
# }

# output "db_identifier" {
#   value = local.db_identifier
# }

# output "db_address" {
#   value = aws_db_instance.rds_db.address
# }

# output "db_endpoint" {
#   value = aws_db_instance.rds_db.endpoint
# }

# output "db_arn" {
#   value = aws_db_instance.rds_db.arn
# }

# output "db_engine" {
#   value = aws_db_instance.rds_db.engine
# }

# output "db_port" {
#   value = aws_db_instance.rds_db.port
# }

#output "sql_cmd" {
# TODO fix command
#  value = "mysql -h${aws_db_instance.rds_db.address} --user ${local.db_username} mysql --password=${nonsensitive(local.db_password)}"
#}

