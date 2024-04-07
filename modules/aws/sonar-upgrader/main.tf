locals {
  upgrade_cmd = templatefile("${path.module}/provision_script.tpl", {
    path                       = path.module
    target_version             = var.target_version
    agentless_gws              = jsonencode(var.agentless_gws)
    dsf_hubs                   = jsonencode(var.dsf_hubs)
    connection_timeout         = var.connection_timeout
    test_connection            = var.test_connection
    run_preflight_validations  = var.run_preflight_validations
    run_upgrade                = var.run_upgrade
    run_postflight_validations = var.run_postflight_validations
    #    clean_old_deployments      = var.clean_old_deployments
    stop_on_failure            = var.stop_on_failure
    tarball_location           = jsonencode(var.tarball_location)
    ignore_healthcheck_warning = var.ignore_healthcheck_warnings
    ignore_healthcheck_checks  = var.ignore_healthcheck_checks
  })
}

resource "null_resource" "upgrade_cmd" {
  provisioner "local-exec" {
    command     = local.upgrade_cmd
    interpreter = ["bash", "-c"]
  }

  triggers = {
    command = local.upgrade_cmd
  }
}
