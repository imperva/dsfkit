
module "statistics" {
  source = "../../../modules/null/statistics"

  id                    = var.id
  deployment_name       = var.deployment_name
  artifact              = var.artifact
  product               = var.product
  resource_type         = var.resource_type
  platform              = "aws"
  account_id            = data.aws_caller_identity.current.account_id
  location              = data.aws_region.current.name
  initialization_status = var.initialization_status
  additional_info       = var.additional_info
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
