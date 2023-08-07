locals {
  upgrade_cmd = templatefile("${path.module}/provision_script.tpl", {
    path                       = path.root
    target_version             = var.target_version
    target_agentless_gws       = jsonencode(var.target_agentless_gws)
    target_hubs                = jsonencode(var.target_hubs)
    run_preflight_validations  = tostring(var.run_preflight_validations)
    run_postflight_validations = tostring(var.run_postflight_validations)
    custom_validations_scripts = var.custom_validations_scripts[0]
    run_upgrade                = tostring(var.run_upgrade)
  })
}

resource "null_resource" "sonar_upgrader" {
  provisioner "local-exec" {
    command = local.upgrade_cmd
    interpreter = ["bash", "-c"]
  }

  triggers = {
    command = local.upgrade_cmd
#    gw_list = var.gw_list,
#    hub_list = var.hub_list,
#    target_version = var.target_version,
#    target_gws_by_id = jsonencode(var.target_agentless_gws),
  }
}
