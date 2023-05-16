locals {
  https_auth_header = base64encode("${var.mx_details.user}:${var.mx_details.password}")

  commands = templatefile("${path.module}/setup.tftpl", {
    cluster_name         = var.cluster_name
    gateway_group_name   = var.gateway_group_name
    delete_gateway_group = var.delete_gateway_group
    mx_address           = var.mx_details.address
    mx_port              = var.mx_details.port
    https_auth_header    = local.https_auth_header
  })
}

resource "null_resource" "cluster_setup" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.commands
  }
  triggers = {
    content = local.commands
  }
}