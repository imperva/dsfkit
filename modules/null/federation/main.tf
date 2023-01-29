#################################
# Federation script
#################################

locals {
  lock_shell_cmds = file("${path.module}/grab_lock.sh")
  federate_hub_cmds = templatefile("${path.module}/federate_hub.tpl", {
    ssh_key_path = var.hub_info.hub_private_ssh_key_path
    dsf_gw_ip    = var.gw_info.gw_ip_address
    dsf_hub_ip   = var.hub_info.hub_ip_address
    hub_ssh_user = var.hub_info.hub_ssh_user
    hub_proxy_address              = var.hub_proxy_info.proxy_address != null ? var.hub_proxy_info.proxy_address : ""
    hub_proxy_private_ssh_key_path = var.hub_proxy_info.proxy_private_ssh_key_path != null ? var.hub_proxy_info.proxy_private_ssh_key_path : ""
    hub_proxy_ssh_user             = var.hub_proxy_info.proxy_ssh_user != null ? var.hub_proxy_info.proxy_ssh_user : ""
  })
  federate_gw_cmds = templatefile("${path.module}/federate_gw.tpl", {
    ssh_key_path       = var.gw_info.gw_private_ssh_key_path
    dsf_gw_ip          = var.gw_info.gw_ip_address
    gw_ssh_user        = var.gw_info.gw_ssh_user
    gw_proxy_address              = var.gw_proxy_info.proxy_address != null ? var.gw_proxy_info.proxy_address : ""
    gw_proxy_private_ssh_key_path = var.gw_proxy_info.proxy_private_ssh_key_path != null ? var.gw_proxy_info.proxy_private_ssh_key_path : ""
    gw_proxy_ssh_user             = var.gw_proxy_info.proxy_ssh_user != null ? var.gw_proxy_info.proxy_ssh_user : ""
  })
  sleep_value = "40s"
}

resource "time_sleep" "sleep" {
  create_duration = local.sleep_value
}

resource "null_resource" "federate_cmds" {
  provisioner "local-exec" {
    command     = "${local.lock_shell_cmds} ${local.federate_hub_cmds} ${local.federate_gw_cmds}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [
    time_sleep.sleep,
  ]
  # triggers = {
  #   binaries_location = "${var.binaries_location.s3_bucket}/${var.binaries_location.s3_key}",
  # }
}
