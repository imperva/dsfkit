locals {
  bastion_host        = var.hub_proxy_info.proxy_address
  bastion_private_key = try(file(var.hub_proxy_info.proxy_private_ssh_key_path), "")
  bastion_user        = var.hub_proxy_info.proxy_ssh_user
  script_path         = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))

  db_policy_by_engine_map = {
    "mysql" : local.mysql_policy,
    "postgres" : local.postgres_policy,
    "sqlserver-ex" : local.mssql_policy
  }
  server_type_by_engine_map = {
    "mysql" : "AWS RDS MYSQL",
    "postgres" : "AWS RDS POSTGRESQL",
    "sqlserver-ex" : "AWS RDS MS SQL SERVER"
  }
}

data "aws_iam_role" "assignee_role" {
  name = split("/", var.assignee_role)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
}

resource "aws_iam_policy" "db_policy" {
  description = "IAM policy for collecting audit"
  policy      = local.db_policy_by_engine_map[var.database_details.db_engine]
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = data.aws_iam_role.assignee_role.name
  policy_arn = aws_iam_policy.db_policy.arn
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


module "onboard_db_to_dsf" {
  source = "../../../modules/null/poc-db-onboarder"

  assignee_gw = var.assignee_gw

  usc_access_token = var.usc_access_token
  enable_audit     = var.enable_audit

  database_data = {
    id = {
      name = "arn"
      value = var.database_details.db_arn
    }
    name        = var.database_details.db_identifier
    hostname    = var.database_details.db_address
    port        = var.database_details.db_port
    server_type = local.server_type_by_engine_map[var.database_details.db_engine]
  }

  cloud_account_data = {
    id = {
      name = "arn"
      value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}"
    }
    name = data.aws_caller_identity.current.account_id
    type = "AWS"
    connections_data = []
  }

  cloud_account_additional_data = {
    auth_mechanism     = "default"
    region             = data.aws_region.current.name
  }
  database_additional_data = {
    region = data.aws_region.current.name
  }

  hub_info                     = var.hub_info
  hub_proxy_info               = var.hub_proxy_info
  terraform_script_path_folder = var.terraform_script_path_folder

  depends_on                   = [aws_iam_role_policy_attachment.policy_attach]
}
