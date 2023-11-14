locals {
  public_ip  = azurerm_linux_virtual_machine.dsf_base_instance.public_ip_address
  private_ip = azurerm_linux_virtual_machine.dsf_base_instance.private_ip_address

  # root volume details
  root_volume_size  = 100
  root_volume_type  = "Standard_LRS"
  root_volume_cache = "ReadWrite"

  # state volume details
  disk_data_size  = var.storage_details.disk_size
  disk_data_type  = var.storage_details.storage_account_type
  disk_data_iops  = var.storage_details.disk_iops_read_write
  disk_data_cache = "ReadWrite"

  security_group_id = length(var.security_group_ids) == 0 ? azurerm_network_security_group.dsf_base_sg.id : var.security_group_ids[0]
}

resource "azurerm_public_ip" "vm_public_ip" {
  count               = var.attach_persistent_public_ip ? 1 : 0
  name                = join("-", [var.name, "public", "ip"])
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

data "azurerm_public_ip" "vm_public_ip" {
  count               = var.attach_persistent_public_ip ? 1 : 0
  name                = join("-", [var.name, "public", "ip"])
  resource_group_name = var.resource_group.name
  depends_on = [
    azurerm_linux_virtual_machine.dsf_base_instance
  ]
}

resource "azurerm_network_interface_security_group_association" "nic_ip_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = local.security_group_id
}

resource "azurerm_linux_virtual_machine" "dsf_base_instance" {
  name                = var.name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  size                = var.instance_type
  admin_username      = local.vm_user

  custom_data = base64encode(local.install_script)

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = local.vm_user
    public_key = var.public_ssh_key
  }

  os_disk {
    disk_size_gb         = local.root_volume_size
    caching              = local.root_volume_cache
    storage_account_type = local.root_volume_type
  }

  source_image_reference {
    publisher = local.vm_image.publisher
    offer     = local.vm_image.offer
    sku       = local.vm_image.sku
    version   = local.vm_image.version
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.dsf_base.id]
  }
  tags = merge(var.tags, { Name = var.name })

  # Ignore changes to the custom_data attribute (Don't replace on userdata change)
  lifecycle {
    ignore_changes = [
      custom_data
    ]
  }
  depends_on = [
    azurerm_role_assignment.dsf_base_storage_role_assignment
  ]
}

resource "azurerm_user_assigned_identity" "dsf_base" {
  name                = var.name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
}

data "azurerm_subscription" "subscription" {
}

resource "azurerm_role_assignment" "dsf_base_storage_role_assignment" {
  scope                = "${data.azurerm_subscription.subscription.id}/resourceGroups/${var.binaries_location.az_resource_group}/providers/Microsoft.Storage/storageAccounts/${var.binaries_location.az_storage_account}/blobServices/default/containers/${var.binaries_location.az_container}"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.dsf_base.principal_id
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.external_data_vol.id
  virtual_machine_id = azurerm_linux_virtual_machine.dsf_base_instance.id
  lun                = "11"
  caching            = local.disk_data_cache
}

resource "azurerm_managed_disk" "external_data_vol" {
  name                 = join("-", [var.name, "data", "disk"])
  location             = var.resource_group.location
  resource_group_name  = var.resource_group.name
  storage_account_type = local.disk_data_type
  create_option        = "Empty"
  disk_size_gb         = local.disk_data_size
  disk_iops_read_write = local.disk_data_iops
  tags                 = var.tags
}

resource "azurerm_network_interface" "nic" {
  name                = join("-", [var.name, "nic"])
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  ip_configuration {
    name                          = join("-", [var.name, "nic"])
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.vm_public_ip[0].id, null)
  }
  tags = var.tags
}
