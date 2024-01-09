locals {
  conf_timeout = 60 * 40

  configuration_elements = concat(
    local.service_group_configuration,
    local.hub_configuration
  )
  commands = <<-EOF
      ${templatefile("${path.module}/configure.tftpl",
  { mx_address             = local.mx_address_for_api
    https_auth_header      = local.https_auth_header
    configuration_elements = local.configuration_elements
    timeout                = local.conf_timeout
})
}
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
