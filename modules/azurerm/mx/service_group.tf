locals {
  site         = "Default Site"
  server_group = "${var.friendly_name}-server-group"

  db_serivces = [
    "PostgreSql",
    "MySql",
    # "MariaDB",
    # "MsSql",
    # "Oracle",
  ]

  service_group_configuration = var.create_server_group == false ? [] : concat([{
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
}