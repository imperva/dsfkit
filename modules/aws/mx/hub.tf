locals {
  default_audit_policy  = "Default Rule - All Events"
  _hub_action_set        = "Send to DSF Hub"
  _hub_action_set_action = local._hub_action_set
  _hub_action_set147        = "Default Archive Action Set"
  _hub_action_set_action147 = local._hub_action_set147
  hub_action_set = local.dam_version != "14.7" ? local._hub_action_set : local._hub_action_set147
  hub_action_set_action = local.dam_version != "14.7" ? local._hub_action_set_action : local._hub_action_set_action147

  # Archiving action set is created differently on 14.7
  dam_version_major = split(".", var.dam_version)[0]
  dam_version_minor = split(".", var.dam_version)[1]
  dam_version = "${local.dam_version_major}.${local.dam_version_minor}"

  action_set_item = var.hub_details == null ? [] : local.dam_version != "14.7" ? [{
    name     = "send_to_hub_action_set" # https://docs.imperva.com/bundle/v14.11-database-activity-monitoring-user-guide/page/78508.htm
    method   = "PUT"
    url_path = "SecureSphere/api/v1/conf/actionSets/${local.hub_action_set}/${local.hub_action_set_action}"
    payload = jsonencode({
      "type" : "SonarArchiver",
      "host" : try(var.hub_details.address, null),
      "port" : try(var.hub_details.port, null),
      "apiToken" : try(var.hub_details.access_token, null)
      "enabled" : true
      "strictCertificateChecking" : false
      }
    )
  }] : [{
    name     = "default_archive_action_set" # https://docs.imperva.com/bundle/v14.7-database-activity-monitoring-user-guide/page/78508.htm
    method   = "POST"
    url_path = "SecureSphere/api/v1/conf/actionSets/${local.hub_action_set}/${local.hub_action_set_action}"
    payload = jsonencode({
      "type" : "SonarArchiver",
      "host" : try(var.hub_details.address, null),
      "port" : try(var.hub_details.port, null),
      "apiToken" : try(var.hub_details.access_token, null)
      "strictCertificateChecking" : false
      "actionInterface": "Send to Sonar"
      }
    )
    }]

  hub_configuration = var.hub_details == null ? [] : concat(local.action_set_item,
    var.large_scale_mode == true ? [] : [{
      name     = "archive_default_audit_policy_to_hub" # https://docs.imperva.com/bundle/v14.11-database-activity-monitoring-user-guide/page/78508.htm
      method   = "PUT"
      url_path = "SecureSphere/api/v1/conf/auditPolicies/${local.default_audit_policy}"
      payload = jsonencode({
        "policy-type" : "db-service",
        "archiving-action-set" : local.hub_action_set,
        "archiving-settings" : "Default Archiving Settings",
        "match-criteria" : [
          {
            "type" : "simple",
            "name" : "Event Type",
            "operation" : "Equals",
            "values" : [
              {
                "value" : "Login"
              },
              {
                "value" : "Query"
              },
              {
                "value" : "Logout"
              }
            ],
            "handle-unknown-values" : false
          }
        ],
        "archive-scheduling" : {
          "occurs" : "none"
        },
        "user-defined-values" : [],
        "data-collection-db-response" : false
        }
      )
      },
      {
        name     = "send_incidents_to_hub" # https://docs.imperva.com/bundle/v14.11-database-activity-monitoring-user-guide/page/78509.htm
        method   = "PUT"
        url_path = "SecureSphere/api/v1/conf/systemDefinitions/send-alerts-to-sonar"
        payload = jsonencode({
          "value" : true
          }
        )
    }]
  )
}