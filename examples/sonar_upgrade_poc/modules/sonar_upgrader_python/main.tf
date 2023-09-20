locals {
  upgrade_cmd = templatefile("${path.module}/provision_script.tpl", {
    path                       = path.root
    target_version             = var.target_version
    agentless_gws              = jsonencode(var.agentless_gws)
    dsf_hubs                   = jsonencode(var.dsf_hubs)
    connection_timeout         = var.connection_timeout
    test_connection            = var.test_connection
    run_preflight_validations  = var.run_preflight_validations
    run_upgrade                = var.run_upgrade
    run_postflight_validations = var.run_postflight_validations
    run_clean_old_deployments  = var.run_clean_old_deployments
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
