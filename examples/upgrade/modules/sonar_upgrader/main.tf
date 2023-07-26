locals {
  upgrade_cmd = templatefile("${path.module}/upgrade.tpl", {

    target_version            = var.target_version
    target_gws_by_id          = jsonencode(var.target_gws_by_id)
    target_hubs_by_id         = jsonencode(var.target_hubs_by_id)
    run_preflight_validation  = var.run_preflight_validation
    run_postflight_validation = var.run_postflight_validation
    # pass the list of custom validation scripts

    custom_validations_scripts =  var.custom_validations_scripts[0]
  })
}


# jsonencode vs tojson
# https://www.terraform.io/docs/configuration/functions/tojson.html
resource "null_resource" "sonar_upgrader" {
  provisioner "local-exec" {
    command     = "${local.upgrade_cmd}"
    interpreter = ["/bin/bash", "-c"]
  }

  triggers = {
    gw_list = "${var.gw_list}",
    hub_list = "${var.hub_list}",
    target_version = "${var.target_version}",
    target_gws_by_id = "${jsonencode(var.target_gws_by_id)}",  
    }

}
