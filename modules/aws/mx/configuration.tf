locals {
  site         = "Default%20Site"
  server_group = "${var.friendly_name}-server-group"
  db_serivces = [
      "PostgreSql",
      "MySql",
      "MsSql",
      "Oracle",
      "MariaDb",
  ]

  configuration_elements = concat([
    {
      name = "default_server_group"
      method   = "POST"
      url_path = "SecureSphere/api/v1/conf/serverGroups/${local.site}/${local.server_group}"
      payload     = "{}"
    }
  ],
  [
    for val in local.db_serivces : {
      name = "db_service_${lower(val)}"
      method   = "POST"
      url_path = "SecureSphere/api/v1/conf/dbServices/${local.site}/${local.server_group}/${lower(val)}"
      payload     = <<-EOF
        {"db-service-type": "${val}"}
      EOF
    }
  ]
  )
}

resource "null_resource" "import_configuration" {
  provisioner "local-exec" {
    command = templatefile("${path.module}/configure.sh", 
                 {mx_address        = module.mx.public_ip
                  https_auth_header = local.https_auth_header
                  configuration_elements = local.configuration_elements})
  }
  depends_on = [
    module.mx
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
}
