locals {
  upgrade_cmd = templatefile("${path.module}/provision_script.tpl", {
    path                       = path.root
    target_version             = var.target_version
    target_gws_by_id           = jsonencode(var.target_gws_by_id)
    target_hubs_by_id          = jsonencode(var.target_hubs_by_id)
    run_preflight_validation   = tostring(var.run_preflight_validation)
    run_postflight_validation  = tostring(var.run_postflight_validation)
    custom_validations_scripts = var.custom_validations_scripts[0]
  })
}

resource "null_resource" "sonar_upgrader" {
  provisioner "local-exec" {
    command = local.upgrade_cmd
    interpreter = ["bash", "-c"]
  }

  triggers = {
    gw_list = var.gw_list,
    hub_list = var.hub_list,
    target_version = var.target_version,
    target_gws_by_id = jsonencode(var.target_gws_by_id),
  }
}
