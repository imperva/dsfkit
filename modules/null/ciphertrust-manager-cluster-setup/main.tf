locals {
  ddc_active_node_commands = var.ddc_node_setup.enabled ? templatefile("${path.module}/ddc_active_node_setup.tftpl", {
    cm_node_address = var.ddc_node_setup.node_address
  }) : null
}

resource "ciphertrust_cluster" "cluster" {
  count = length(var.nodes)> 1 ? 1 : 0
  dynamic "node" {
    for_each = { for index, instance in var.nodes : index => instance }
    content {
      host           = node.value.host
      public_address = node.value.public_address
      original       = node.value.host == var.nodes[0].host && node.value.public_address == var.nodes[0].public_address
    }
  }
}

resource "null_resource" "ddc_active_node_setup" {
  count = var.ddc_node_setup.enabled ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.ddc_active_node_commands
    # Using env vars for credentials instead of template vars for security reasons
    environment = {
      CM_USER = nonsensitive(var.credentials.user)
      CM_PASSWORD = nonsensitive(var.credentials.password)
    }
  }
  triggers = {
    content = local.ddc_active_node_commands
  }
  depends_on = [
    ciphertrust_cluster.cluster
  ]
}
