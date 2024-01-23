output "db_username" {
  value = "${local.db_username}@${local.db_identifier}"
}

output "db_password" {
  value = nonsensitive(local.db_password)
}

output "db_name" {
  value = local.db_identifier
}

output "db_identifier" {
  value = local.db_identifier
}

output "db_address" {
  value = local.db_address
}

output "db_id" {
  value = azurerm_mssql_database.db.id
}

output "db_server_id" {
  value = azurerm_mssql_server.server.id
}

output "db_engine" {
  value = "mssql"
}

output "db_port" {
  value = 1433
}

output "sql_cmd" {
  value = "sqlcmd -S ${local.db_address} --database-name ${local.db_identifier} -U ${local.db_username}@${local.db_identifier} -P'${nonsensitive(local.db_password)}' -Q 'SELECT AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate FROM SalesLT.Address;'"
}
