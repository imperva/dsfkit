locals {
  display_name = var.name
}

resource "azurerm_virtual_machine_extension" "custom_script" {
  for_each             = var.custom_scripts
  name                 = "customScript_${each.key}"
  virtual_machine_id   = azurerm_linux_virtual_machine.dsf_base_instance.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = <<PROTECTED_SETTINGS
    {
        "commandToExecute": "${each.value}"
    }
PROTECTED_SETTINGS

  timeouts {
    create = "60m"
  }

  # Ignore changes to the protected_settings attribute (Don't replace on custom_script change)
  lifecycle {
    ignore_changes = [
      protected_settings,
    ]
  }
}

module "statistics" {
  source = "../../../modules/azurerm/statistics"
  count  = var.send_usage_statistics ? 1 : 0

  deployment_name = var.name
  product         = "DAM"
  resource_type   = var.resource_type
  artifact        = join(":", compact([local.vm_image.publisher, local.vm_image.offer, local.vm_image.sku, local.vm_image.version]))
  location        = var.resource_group.location
}

resource "null_resource" "readiness" {
  count = var.instance_readiness_params.enable == true ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOF
    TIMEOUT=${var.instance_readiness_params.timeout}
    START=$(date +%s)

    operation() {
      ${var.instance_readiness_params.commands}
    }

    # Perform the operation in a loop until the timeout is reached
    while true; do
      # Check if the timeout has been reached
      NOW=$(date +%s)
      ELAPSED=$((NOW-START))
      if [ $ELAPSED -gt $TIMEOUT ]; then
        echo "Timeout reached. To obtain additional information, refer to the /var/log/azure_arm.log file located on the remote server."
        exit 1
      fi

      operation

      sleep 60
    done
    EOF
  }

  triggers = {
    instance_id = azurerm_linux_virtual_machine.dsf_base_instance.id
    commands    = var.instance_readiness_params.commands
  }
  depends_on = [
    module.statistics,
    azurerm_virtual_machine_extension.custom_script
  ]
}

module "statistics_success" {
  source = "../../../modules/azurerm/statistics"
  count  = var.send_usage_statistics ? 1 : 0

  id         = module.statistics[0].id
  status     = "success"
  depends_on = [null_resource.readiness]
}
