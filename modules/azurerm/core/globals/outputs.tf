output "salt" {
  value = resource.random_id.salt.hex
}

output "my_ip" {
  value = trimspace(data.http.workstation_public_ip.response_body)
}

output "now" {
  value = resource.time_static.current_time.id
}

output "random_password" {
  value = resource.random_password.pass.result
}

output "current_user_object_id" {
  value = data.azurerm_client_config.current.object_id
}

output "current_user_name" {
  value = length(data.azuread_service_principal.current) > 0 ? data.azuread_service_principal.current[0].display_name : data.azuread_user.current[0].display_name
}

output "tags" {
  value = {
    terraform_workspace = terraform.workspace
    vendor              = "Imperva"
    product             = "EDSF"
    terraform           = "true"
    environment         = "demo"
    creation_timestamp  = resource.time_static.current_time.id
  }
}

output "tarball_location" {
  value = {
    az_storage_account = var.tarball_location.storage_account
    az_container       = var.tarball_location.container
    az_blob            = local.blob_object
  }
}
