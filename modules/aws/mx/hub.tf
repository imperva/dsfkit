locals {
  default_audit_policy  = "Default Rule - All Events"
  hub_action_set        = "Send to DSF Hub"
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
    }]
    ,
    var.large_scale_mode == true ? [] : [{
      name     = "archive_default_audit_policy_to_hub"
      method   = "PUT"
      url_path = "SecureSphere/api/v1/conf/auditPolicies/${local.default_audit_policy}"
      payload = jsonencode({
        "policy-type": "db-service",
        "archiving-action-set" : local.hub_action_set,
        "archiving-settings" : "Default Archiving Settings",
        "match-criteria": [
          {
            "type": "simple",
            "name": "Event Type",
            "operation": "Equals",
            "values": [
              {
                "value": "Login"
              },
              {
                "value": "Query"
              },
              {
                "value": "Logout"
              }
            ],
            "handle-unknown-values": false
          }
        ],
        "archive-scheduling": {
          "occurs": "none"
        },
        "user-defined-values": [],
        "data-collection-db-response": false
      }
    )
    }]
  )
}