locals {
  bastion_host        = var.hub_proxy_info.proxy_address
  bastion_private_key = try(file(var.hub_proxy_info.proxy_private_ssh_key_path), "")
  bastion_user        = var.hub_proxy_info.proxy_ssh_user
  script_path         = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))

  server_type_by_engine_map = {
    "mssql" : "AZURE MS SQL SERVER"
  }
}

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "dsf_base_owner_role_assignment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Owner"
  principal_id         = var.assignee_role
}

module "onboard_db_to_dsf" {
  source = "../../../modules/null/poc-db-onboarder"

  assignee_gw = var.assignee_gw

  usc_access_token = var.usc_access_token
  enable_audit     = var.enable_audit

  database_data = {
    id          = var.database_details.db_server_id
    name        = var.database_details.db_identifier
    location    = var.resource_group.location
    hostname    = var.database_details.db_address
    port        = var.database_details.db_port
    server_type = local.server_type_by_engine_map[var.database_details.db_engine]
  }

  cloud_account_data = {
    id   = data.azurerm_subscription.current.id
    name = data.azurerm_subscription.current.display_name
    type = "AZURE"
    connections_data = [
      {
        reason = "default"
        connectionData = {
          auth_mechanism  = "managed_identity"
          subscription_id = data.azurerm_subscription.current.subscription_id,
        }
      }
    ]
  }

  hub_info                     = var.hub_info
  hub_proxy_info               = var.hub_proxy_info
  terraform_script_path_folder = var.terraform_script_path_folder
  depends_on                   = [azurerm_role_assignment.dsf_base_owner_role_assignment]
}
