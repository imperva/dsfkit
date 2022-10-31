resource "time_sleep" "wait_120_seconds" {
  create_duration = "120s"
}

#################################
# Federation script
#################################

locals {
  lock_shell_cmds   = templatefile("${path.module}/grab_lock.sh", {index = var.index})
  federate_hub_cmds = templatefile("${path.module}/federate_hub.tpl", {
    ssh_key_path        = var.hub_ssh_key_path
    dsf_gw_ip           = var.gw
    dsf_hub_ip          = var.hub
  })
  federate_gw_cmds = templatefile("${path.module}/federate_gw.tpl", {
    ssh_key_path        = var.hub_ssh_key_path
    dsf_gw_ip           = var.gw
    dsf_hub_ip          = var.hub
  })
}

resource "null_resource" "federate_cmds" {
  provisioner "local-exec" {
    command         = "${local.lock_shell_cmds} ${local.federate_hub_cmds} ${local.federate_gw_cmds}"
    interpreter     = ["/bin/bash", "-c"]
  }
  depends_on = [
    time_sleep.wait_120_seconds,
  ]
  triggers = {
    installation_source = "${var.installation_source}",
  }
}
