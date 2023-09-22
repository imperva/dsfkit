
module "statistics" {
  source = "../../../modules/null/statistics"

  id              = var.id
  deployment_name = var.deployment_name
  artifact        = var.artifact
  product         = var.product
  resource_type   = var.resource_type
  platform        = "azure"
  account_id      = data.azurerm_client_config.current.subscription_id
  location        = var.location
  status          = var.status
  additional_info = var.additional_info
}

data "azurerm_client_config" "current" {
}
