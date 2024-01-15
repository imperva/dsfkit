locals {
  security_group_id = length(var.security_group_ids) == 0 ? azurerm_network_security_group.dsf_base_sg.id : var.security_group_ids[0]

  public_ip  = azurerm_linux_virtual_machine.vm.public_ip_address
  private_ip = azurerm_linux_virtual_machine.vm.private_ip_address
#  public_dns

  # root volume details
  root_volume_size  = 100
  root_volume_type  = "Standard_LRS"
  root_volume_cache = "ReadWrite"

  install_script = templatefile("${path.module}/setup.tftpl", {
    vault_name                              = azurerm_key_vault.vault.name
    admin_registration_password_secret_name = azurerm_key_vault_secret.admin_analytics_registration_password.name
    admin_password_secret_name              = azurerm_key_vault_secret.admin_password.name
  })

#  custom_script = templatefile("${path.module}/setup.tftpl", {
##    vault_name                              = azurerm_key_vault.vault.name
#    admin_registration_password = var.admin_registration_password
#    admin_password              = var.admin_password
#  })
}

resource "azurerm_network_interface" "nic" {
  name                = var.name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location

  ip_configuration {
    name                          = join("-", [var.name, "nic"])
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.vm_public_ip[0].id, null)
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "nic_sg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = local.security_group_id
}

resource "azurerm_public_ip" "vm_public_ip" {
  count               = var.attach_persistent_public_ip ? 1 : 0
  name                = join("-", [var.name, "public", "ip"])
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.name
  resource_group_name   = var.resource_group.name
  location              = var.resource_group.location
  size                  = var.instance_size
  admin_username        = local.vm_user

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    public_key = var.ssh_public_key
    username   = local.vm_user
  }

  os_disk {
#    disk_size_gb         = local.root_volume_size
    disk_size_gb         = var.storage_details.disk_size
    caching              = local.root_volume_cache
    storage_account_type = local.root_volume_type
  }

  source_image_id = "${data.azurerm_subscription.subscription.id}/resourceGroups/${var.image_details.resource_group_name}/providers/Microsoft.Compute/images/${var.image_details.image_id}"

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.user_assigned_identity.id
    ]
  }

  tags = var.tags

  custom_data = base64encode(local.install_script)

  # Ignore changes to the custom_data attribute (Don't replace on userdata change)
  lifecycle {
    ignore_changes = [
      custom_data
    ]
  }
}

#resource "azurerm_virtual_machine_extension" "custom_script" {
#  name                 = "customScript_setup"
#  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
#  publisher            = "Microsoft.Azure.Extensions"
#  type                 = "CustomScript"
#  type_handler_version = "2.1"
#
#  protected_settings = <<PROTECTED_SETTINGS
#    {
#        "script": "${base64encode(local.custom_script)}"
#    }
#PROTECTED_SETTINGS
#
#  timeouts {
#    create = "60m"
#  }
#}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  name                = var.name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

data "azurerm_subscription" "subscription" {}

resource "azurerm_role_assignment" "vm_identity_storage_role_assignment" {
  scope                = data.azurerm_subscription.subscription.id
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
  role_definition_name = "Reader"
}

# disk attachment
resource "azurerm_managed_disk" "external_data_vol" {
  name                 = join("-", [var.name, "data", "disk"])
  location             = var.resource_group.location
  resource_group_name  = var.resource_group.name
  create_option        = "Empty"
  storage_account_type = var.storage_details.storage_account_type
  disk_size_gb         = var.storage_details.disk_size
  disk_iops_read_write = var.storage_details.disk_iops_read_write
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  managed_disk_id    = azurerm_managed_disk.external_data_vol.id
  lun                = 11
  caching            = "ReadWrite"
}