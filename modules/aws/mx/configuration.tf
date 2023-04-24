locals {
  conf_timeout = 60 * 15
  site         = "Default%20Site"
  server_group = "${var.friendly_name}-server-group"
  db_serivces = [
    "PostgreSql",
    "MySql",
    "MariaDB",
    # "MsSql",
    # "Oracle",
  ]

  configuration_elements = concat([
    {
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
        payload  = <<-EOF
        {"db-service-type": "${val}"}
      EOF
      }
    ]
  )
}

resource "null_resource" "import_configuration" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOF
      ${templatefile("${path.module}/configure.sh",
        { mx_address        = local.mx_address_for_api
          https_auth_header = local.https_auth_header
          configuration_elements = local.configuration_elements })}
    EOF
}
depends_on = [
  module.mx
]
}
