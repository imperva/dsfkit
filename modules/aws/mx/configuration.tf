locals {
  conf_timeout                = 60 * 15
  site                        = "Default%20Site"
  server_group                = "${var.friendly_name}-server-group"
  dra_action_set              = "Send%20to%20DRA%20Behavior%20Analytics"
  dra_all_events_audit_policy = "CounterBreach%20for%20Database%20-%20All%20Events"
  dra_all_logins_audit_policy = "CounterBreach%20for%20Database%20-%20Logins%20Logouts"
  db_serivces = [
    "PostgreSql",
    "MySql",
    "MariaDB",
    # "MsSql",
    # "Oracle",
  ]

  service_group_configuration = var.create_service_group == false ? [] : concat([{
    name     = "default_server_group"
    method   = "POST"
    url_path = "SecureSphere/api/v1/conf/serverGroups/${local.site}/${local.server_group}"
    payload  = "{}"
    }
    ],
    [
      for val in local.db_serivces : {
        name     = "db_service_${lower(val)}"
        method   = "POST"
        url_path = "SecureSphere/api/v1/conf/dbServices/${local.site}/${local.server_group}/${lower(val)}"
        payload  = jsonencode({ "db-service-type" : val })
      }
    ]
  )
  dra_configuration = var.dra_configuration == null ? [] : [
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
        "host" : try(var.dra_configuration.address, null),
        "port" : try(var.dra_configuration.port, null),
        "password" : try(var.dra_configuration.password, null),
        "username" : try(var.dra_configuration.username, null),
        "remoteDirectory" : try(var.dra_configuration.remoteDirectory, null),
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

  configuration_elements = concat(
    local.service_group_configuration,
    local.dra_configuration
  )
  commands = <<-EOF
      ${templatefile("${path.module}/configure.tftpl",
  { mx_address        = local.mx_address_for_api
    https_auth_header = local.https_auth_header
configuration_elements = local.configuration_elements })}
    EOF
}

resource "null_resource" "import_configuration" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.commands
  }
  triggers = {
    content = local.commands
  }
  depends_on = [
    module.mx
  ]
}
