locals {
  hub_action_set        = "Send%20to%20DSF%20Hub"
  hub_action_set_action = local.hub_action_set

  hub_configuration = var.hub_details == null ? [] : concat([{
    name     = "send_to_hub_action_set"
    method   = "PUT"
    url_path = "SecureSphere/api/v1/conf/actionSets/${local.hub_action_set}/${local.hub_action_set_action}"
    payload = jsonencode({
      "type" : "SonarArchiver",
      "host" : try(var.hub_details.address, null),
      "port" : try(var.hub_details.port, null),
      "apiToken" : try(var.hub_details.access_token, null)
      # "encryptedToken": false
      "enabled" : true
      "strictCertificateChecking" : false
      }
    )
    }
    ]
  )
}