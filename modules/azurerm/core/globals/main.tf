locals {
  sonar_tarball_s3_key_map = {
    "4.12"      = "jsonar-4.12.0.10.0.tar.gz"
    "4.12.0.10" = "jsonar-4.12.0.10.0.tar.gz"

    "4.11"     = "jsonar-4.11.0.0.0.tar.gz"
    "4.11.0.0" = "jsonar-4.11.0.0.0.tar.gz"

    "4.10"     = "jsonar-4.10.0.1.0.tar.gz"
    "4.10.0.1" = "jsonar-4.10.0.1.0.tar.gz"
    "4.10.0.0" = "jsonar-4.10.0.0.0.tar.gz"

    "4.9" = "jsonar-4.9.c_20221129220420.tar.gz"
  }
  sonar_supported_versions       = keys(local.sonar_tarball_s3_key_map)
  sonar_fully_supported_versions = setsubtract(local.sonar_supported_versions, ["4.9", "4.10.0.0", "4.10.0.1", "4.10"])
  blob_object                    = var.tarball_blob != null ? var.tarball_blob : local.sonar_tarball_s3_key_map[var.sonar_version]
  blob_object_version            = regex("\\d\\.\\d*", local.blob_object)
}

locals {
  is_service_principal = data.azuread_directory_object.current.type == "ServicePrincipal"
}

resource "random_id" "salt" {
  byte_length = 2
}

resource "null_resource" "postpone_data_to_apply_phase" {
  triggers = {
    always_run = timestamp()
  }
}

data "http" "workstation_public_ip" {
  url = "http://ipv4.icanhazip.com"
  depends_on = [
    null_resource.postpone_data_to_apply_phase
  ]
}

data "azurerm_client_config" "current" {
}

data "azuread_directory_object" "current" {
  object_id = data.azurerm_client_config.current.object_id
}

data "azuread_service_principal" "current" {
  count     = local.is_service_principal ? 1 : 0
  object_id = data.azurerm_client_config.current.object_id
}

data "azuread_user" "current" {
  count     = local.is_service_principal ? 0 : 1
  object_id = data.azurerm_client_config.current.object_id
}

resource "time_static" "current_time" {}

resource "random_password" "pass" {
  length           = 14
  special          = true
  numeric          = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "*+#%^:/~.,[]_"
}
