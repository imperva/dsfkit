resource "random_id" "salt" {
  byte_length = 2
}

locals {
  agent_installation_dir = local.os_params[local.os_type].agent_installation_dir
  custom_script = templatefile("${path.module}/setup.tftpl", {
    package_install                = local.os_params[local.os_type].package_install
    database_installation_commands = local.os_params[local.os_type].database_installation_commands[local.db_type]
    database_queries_commands      = local.os_params[local.os_type].database_queries_commands[local.db_type]
    agent_installation_dir         = local.os_params[local.os_type].agent_installation_dir
    az_storage_account             = var.binaries_location.az_storage_account
    az_container                   = var.binaries_location.az_container
    az_blob                        = var.binaries_location.az_blob
    agent_gateway_host             = var.registration_params.agent_gateway_host
    secure_password                = var.registration_params.secure_password
    site                           = var.registration_params.site
    server_group                   = var.registration_params.server_group
    agent_name                     = join("-", [var.friendly_name, random_id.salt.hex])
  })
}


resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "customScript_setup"
  virtual_machine_id   = azurerm_linux_virtual_machine.agent.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = <<PROTECTED_SETTINGS
    {
        "script": "${base64encode(local.custom_script)}"
    }
PROTECTED_SETTINGS

  timeouts {
    create = "60m"
  }

  # Ignore changes to the protected_settings attribute (Don't replace on custom_script change)
  lifecycle {
    ignore_changes = [
      protected_settings,
    ]
  }
}