locals {
  web_console_username = "admin"

  ddc_active_node_commands = var.ddc_node_setup.enabled ? templatefile("${path.module}/ddc_active_node_setup.tftpl", {
    cm_node_address = var.ddc_node_setup.node_address
  }) : null
}

resource "ciphertrust_cluster" "cluster" {
  count = length(var.ciphertrust_instances)> 1 ? 1 : 0
  dynamic "node" {
    for_each = { for index, instance in var.ciphertrust_instances : index => instance }
    content {
      host           = node.value.host
      public_address = node.value.public_address
      original       = node.value.host == var.ciphertrust_instances[0].host && node.value.public_address == var.ciphertrust_instances[0].public_address
    }
  }
}

resource "null_resource" "ddc_active_node_setup" {
  count = var.ddc_node_setup.enabled ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.ddc_active_node_commands
    environment = {
      CM_USER = nonsensitive(var.cm_details.user)
      CM_PASSWORD = nonsensitive(var.cm_details.password)
    }
  }
  triggers = {
    content = local.ddc_active_node_commands
  }
  depends_on = [
    ciphertrust_cluster.cluster
  ]
}
