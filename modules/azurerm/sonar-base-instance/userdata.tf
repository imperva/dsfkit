locals {
  bastion_host        = try(var.proxy_info.proxy_address, null)
  bastion_private_key = try(file(var.proxy_info.proxy_private_ssh_key_path), "")
  bastion_user        = try(var.proxy_info.proxy_ssh_user, null)

  instance_address = var.use_public_ip ? local.public_ip : local.private_ip
  display_name     = var.name

  script_path = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))
  install_script = templatefile("${path.module}/setup.tftpl", {
    resource_type                       = var.resource_type
    az_storage_account                  = var.binaries_location.az_storage_account
    az_container                        = var.binaries_location.az_container
    az_blob                             = var.binaries_location.az_blob
    display_name                        = local.display_name
    password_secret                     = local.password_secret_name
    hub_sonarw_public_key               = var.resource_type == "agentless-gw" ? var.hub_sonarw_public_key : ""
    main_node_sonarw_public_key         = local.main_node_sonarw_public_key
    vault_name                          = azurerm_key_vault.vault.name
    main_node_sonarw_private_key_secret = azurerm_key_vault_secret.sonarw_private_key_secret.name
    jsonar_uuid                         = random_uuid.jsonar_uuid.result
    additional_install_parameters       = var.additional_install_parameters
    firewall_ports                      = join(" ", flatten([for i in var.security_groups_config : i.tcp]))
    access_tokens_array                 = local.access_tokens_array
  })
}

resource "random_uuid" "jsonar_uuid" {}

module "statistics" {
  source = "../../../modules/azurerm/statistics"
  count  = var.send_usage_statistics ? 1 : 0

  deployment_name = var.name
  product         = "SONAR"
  resource_type   = var.resource_type
  artifact        = "blob://${sha256(var.binaries_location.az_storage_account)}/${sha256(var.binaries_location.az_container)}/${var.binaries_location.az_blob}"
  location        = var.resource_group.location
}

resource "null_resource" "readiness" {
  count = var.skip_instance_health_verification == true ? 0 : 1
  connection {
    type        = "ssh"
    user        = local.vm_user
    private_key = file(var.ssh_key_path)
    host        = local.instance_address

    timeout = "5m"

    bastion_host        = local.bastion_host
    bastion_private_key = local.bastion_private_key
    bastion_user        = local.bastion_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = [
      "if ! sudo timeout 3600 cloud-init status --wait | grep done &>/dev/null; then",
      "  ([[ -f /var/log/cloud-init-output.log ]] && sudo cat /var/log/cloud-init-output.log) || sudo grep cloud-init /var/log/messages;",
      "  echo;",
      "  sudo cloud-init status;",
      "  exit 1;",
      "fi"
    ]
  }

  triggers = {
    instance_id = azurerm_linux_virtual_machine.dsf_base_instance.id
  }

  depends_on = [
    azurerm_network_interface_security_group_association.nic_ip_association,
    module.statistics
  ]
}

module "statistics_success" {
  source = "../../../modules/azurerm/statistics"
  count  = var.send_usage_statistics ? 1 : 0

  id         = module.statistics[0].id
  status     = "success"
  depends_on = [null_resource.readiness]
}
