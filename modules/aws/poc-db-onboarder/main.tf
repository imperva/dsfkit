locals {
  bastion_host        = var.hub_proxy_info.proxy_address
  bastion_private_key = try(file(var.hub_proxy_info.proxy_private_ssh_key_path), "")
  bastion_user        = var.hub_proxy_info.proxy_ssh_user
  script_path         = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))

  db_policy_by_engine_map = {
    "mysql" : local.mysql_policy,
    "sqlserver-ex" : local.mssql_policy
  }
  server_type_by_engine_map = {
    "mysql" : "AWS RDS MYSQL",
    "sqlserver-ex" : "AWS RDS MS SQL SERVER"
  }
}

data "aws_iam_role" "assignee_role" {
  name = split("/", var.assignee_role)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
}

resource "aws_iam_policy" "db_policy" {
  description = "IAM policy for collecting audit"
  policy      = local.db_policy_by_engine_map[var.database_details.db_engine]
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = data.aws_iam_role.assignee_role.name
  policy_arn = aws_iam_policy.db_policy.arn
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  cloud_account_data = {
    data = {
      applianceId   = 1,
      applianceType = "DSF_HUB",
      id            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}",
      serverType    = "AWS",
      auditState    = "NO",
      gatewayId     = var.assignee_gw
      assetData = {
        admin_email        = "admin@email.com",
        "Server Port"      = 443,
        asset_display_name = "Auto Onboarded AWS Account",
        auth_mechanism     = "default",
        arn                = "arn:aws:iam::${data.aws_caller_identity.current.account_id}",
        region             = data.aws_region.current.name,
      }
    }
  }
  database_asset_data = {
    data : {
      applianceType : "DSF_HUB",
      applianceId : 1,
      serverType : local.server_type_by_engine_map[var.database_details.db_engine],
      gatewayId : var.assignee_gw,
      parentAssetId : local.cloud_account_data.data.id,
      assetData : {
        "Server Port" : var.database_details.db_port,
        database_name : var.database_details.db_name,
        db_engine : var.database_details.db_engine,
        auth_mechanism : "password",
        username : var.database_details.db_username,
        password : var.database_details.db_password,
        region : data.aws_region.current.name,
        asset_source : "AWS",
        "Server Host Name" : var.database_details.db_address,
        admin_email = "admin@email.com",
        arn : var.database_details.db_arn,
        asset_display_name : var.database_details.db_identifier,
        isMonitored : true
      }
    }
  }
}

resource "null_resource" "connect_dsf_to_db" {
  connection {
    type        = "ssh"
    user        = var.hub_info.hub_ssh_user
    private_key = file(var.hub_info.hub_private_ssh_key_path)
    host        = var.hub_info.hub_ip_address

    bastion_host        = local.bastion_host
    bastion_private_key = local.bastion_private_key
    bastion_user        = local.bastion_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/onboard.tftpl", {
        cloud_account_data  = jsonencode(local.cloud_account_data),
        database_asset_data = jsonencode(local.database_asset_data)
        db_arn              = var.database_details.db_arn
        account_arn         = local.cloud_account_data.data.id
      })
    ]
  }
  triggers = {
    db_arn = var.database_details.db_arn
  }
  depends_on = [
    aws_iam_role_policy_attachment.policy_attach
  ]
}
