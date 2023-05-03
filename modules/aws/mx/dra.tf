locals {
  dra_action_set              = "Send%20to%20DRA%20Behavior%20Analytics"
  dra_all_events_audit_policy = "CounterBreach%20for%20Database%20-%20All%20Events"
  dra_all_logins_audit_policy = "CounterBreach%20for%20Database%20-%20Logins%20Logouts"

  dra_configuration = var.dra_details == null ? [] : [
    {
      name     = "send_to_dra_action_set"
      method   = "POST"
      url_path = "SecureSphere/api/v1/conf/actionSets/${local.dra_action_set}"
      payload  = jsonencode({ "type" : "archiving" })
    },
    {
      name     = "send_to_dra_action_set_action"
      method   = "POST"
      url_path = "SecureSphere/api/v1/conf/actionSets/${local.dra_action_set}/scp"
      payload = jsonencode({
        "type" : "ScpArchive",
        "host" : try(var.dra_details.address, null),
        "port" : try(var.dra_details.port, null),
        "password" : try(var.dra_details.password, null),
        "username" : try(var.dra_details.username, null),
        "remoteDirectory" : try(var.dra_details.remoteDirectory, null),
        "useAuthenticationKey" : false,
        "authenticationKeyPath" : " ",
        "authenticationKeyPassphrase" : " "
        }
      )
    },
    {
      name     = "dra_all_events_audit_policy"
      method   = "PUT"
      url_path = "SecureSphere/SecureSphere/api/v1/conf/auditPolicies/${local.dra_all_events_audit_policy}"
      payload = jsonencode({
        "counterbreach-policy-enabled" : true,
        "archiving-action-set" : local.dra_action_set,
        "archiving-settings" : "Default Archiving Settings"
        "archive-scheduling" : {
          "occurs" : "recurring",
          "recurring" : {
            "frequency" : "daily",
            "daily" : {
              "every-number-of-days" : 1
            },
            "starting-from" : formatdate("YYYY-MM-DD", timestamp()),
            "at-time" : "03:00:00"
          }
        }
        }
      )
    },
    {
      name     = "dra_all_logins_audit_policy"
      method   = "PUT"
      url_path = "SecureSphere/SecureSphere/api/v1/conf/auditPolicies/${local.dra_all_logins_audit_policy}"
      payload = jsonencode({
        "counterbreach-policy-enabled" : true,
        "archiving-action-set" : local.dra_action_set,
        "archiving-settings" : "Default Archiving Settings"
        "archive-scheduling" : {
          "occurs" : "recurring",
          "recurring" : {
            "frequency" : "daily",
            "daily" : {
              "every-number-of-days" : 1
            },
            "starting-from" : formatdate("YYYY-MM-DD", timestamp()),
            "at-time" : "02:30:00"
          }
        }
        }
      )
    }
  ]
}