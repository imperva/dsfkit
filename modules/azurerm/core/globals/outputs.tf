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

output "current_user_name" {
  value = data.azuread_user.current.mail_nickname
}

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