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

output "current_user_arn" {
  value = data.azurerm_client_config.current.client_id
}

# output "current_user_name" {
#   value = split("/", data.aws_caller_identity.current.arn)[1] // arn:aws:iam::xxxxxxxxx:user/name
# }

# output "availability_zones" {
#   value = sort(data.aws_availability_zones.available.names)
# }

# output "region" {
#   value = data.aws_region.current.name
# }

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