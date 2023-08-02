locals {
  bastion_host        = try(var.proxy_info.proxy_address, null)
  bastion_private_key = try(file(var.proxy_info.proxy_private_ssh_key_path), "")
  bastion_user        = try(var.proxy_info.proxy_ssh_user, null)

  public_ip        = try(data.azurerm_public_ip.vm_public_ip[0].ip_address, null)
  private_ip       = azurerm_network_interface.nic.private_ip_address
  instance_address = var.use_public_ip ? local.public_ip : local.private_ip
  display_name     = "DSF-${var.resource_type}-${var.name}"

  install_script = templatefile("${path.module}/setup.tpl", {
    resource_type                          = var.resource_type
    az_storage_account                     = var.binaries_location.az_storage_account
    az_container                           = var.binaries_location.az_container
    az_blob                                = var.binaries_location.az_blob
    display-name                           = local.display_name
    web_console_admin_password             = var.password
    secweb_console_admin_password          = var.password
    sonarg_pasword                         = var.password
    sonargd_pasword                        = var.password
    hub_sonarw_public_key                  = var.resource_type == "gw" ? var.hub_sonarw_public_key : ""
    primary_node_sonarw_public_key         = local.primary_node_sonarw_public_key
    primary_node_sonarw_private_key_vault  = azurerm_key_vault.vault.name
    primary_node_sonarw_private_key_secret = azurerm_key_vault_secret.sonarw_private_key_secret.name
    public_fqdn                            = var.use_public_ip ? "True" : ""
    uuid                                   = random_uuid.uuid.result
    additional_install_parameters          = var.additional_install_parameters
    firewall_ports                         = join(" ", flatten([ for i in var.security_groups_config : i.tcp ]))
  })
}

resource "random_uuid" "uuid" {}

resource "null_resource" "wait_for_installation_completion" {
  count = var.skip_instance_health_verification == true ? 0 : 1
  connection {
    type        = "ssh"
    user        = local.vm_user
    private_key = file(var.ssh_key_path)
    host        = local.instance_address

    timeout = "1m"

    bastion_host        = local.bastion_host
    bastion_private_key = local.bastion_private_key
    bastion_user        = local.bastion_user
  }

  provisioner "remote-exec" {
    inline = [
      "if ! sudo timeout 1200 sudo cloud-init status --wait | grep done &>/dev/null; then",
      "  cat /var/log/cloud-init-output.log;",
      "  echo;",
      "  sudo cloud-init status;",
      "  exit 1;",
      "fi"
    ]
  }

  triggers = {
    installation_file = azurerm_linux_virtual_machine.dsf_base_instance.id
  }

  depends_on = [
    azurerm_linux_virtual_machine.dsf_base_instance,
    azurerm_network_interface_security_group_association.nic_ip_association
  ]
}
