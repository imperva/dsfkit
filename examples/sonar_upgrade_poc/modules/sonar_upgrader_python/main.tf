locals {
  upgrade_cmd = templatefile("${path.module}/provision_script.tpl", {
    path                       = path.root
    target_version             = var.target_version
    agentless_gws              = jsonencode(var.agentless_gws)
    dsf_hubs                   = jsonencode(var.dsf_hubs)
    run_preflight_validations  = tostring(var.run_preflight_validations)
    run_upgrade                = tostring(var.run_upgrade)
    run_postflight_validations = tostring(var.run_postflight_validations)
    custom_validations_scripts = var.custom_validations_scripts[0]
  })
}

resource "null_resource" "sonar_upgrader" {
  provisioner "local-exec" {
    command = local.upgrade_cmd
    interpreter = ["bash", "-c"]
  }

  triggers = {
    command = local.upgrade_cmd
  }
}
