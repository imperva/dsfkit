locals {
  bastion_host        = var.hub_proxy_info.proxy_address
  bastion_private_key = try(file(var.hub_proxy_info.proxy_private_ssh_key_path), "")
  bastion_user        = var.hub_proxy_info.proxy_ssh_user
  script_path         = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))
}

locals {
  applianceType = "DSF_HUB"
  admin_email   = "admin@email.com"

  cloud_account_data = {
    data = {
      applianceId   = 1,
      applianceType = local.applianceType,
      serverType    = var.cloud_account_data.type,
      gatewayId     = var.assignee_gw
      id            = var.cloud_account_data.id.value,
      assetData = merge({
        admin_email                      = local.admin_email,
        asset_display_name               = "Auto Onboarded Account: (${var.cloud_account_data.name})",
        (var.cloud_account_data.id.name) = var.cloud_account_data.id.value,
        "Server Host Name"               = "${var.cloud_account_data.type}.com",
        connections                      = var.cloud_account_data.connections_data
        },
      var.cloud_account_additional_data)
    }
  }

  database_data = {
    data : {
      applianceId : 1,
      applianceType : local.applianceType,
      gatewayId : var.assignee_gw,
      parentAssetId : local.cloud_account_data.data.id,
      serverType : var.database_data.server_type,
      id = var.database_data.id.value,
      assetData : merge({
        admin_email = local.admin_email,
        asset_display_name : var.database_data.name,
        (var.database_data.id.name) = var.database_data.id.value,
        "Server Host Name" : var.database_data.hostname,
        "Server Port" : var.database_data.port,
        "Server IP" : var.database_data.hostname,
        isMonitored : var.enable_audit
        },
        var.database_additional_data
      )
    }
  }
}

resource "null_resource" "onboard_db_to_dsf" {
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
        account_id          = urlencode(local.cloud_account_data.data.id)
        database_asset_data = jsonencode(local.database_data)
        database_id         = urlencode(local.database_data.data.id)
        usc_access_token    = var.usc_access_token
        enable_audit        = var.enable_audit
      })
    ]
  }

  triggers = {
    db_id = var.database_data.id.name
    #    always_run = "${timestamp()}"
  }
}
