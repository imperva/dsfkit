locals {
  public_ip  = azurerm_linux_virtual_machine.dsf_base_instance.public_ip_address
  private_ip = azurerm_linux_virtual_machine.dsf_base_instance.private_ip_address

  # app disk details
  disk_app_size  = 100
  disk_app_type  = "Standard_LRS"
  disk_app_cache = "ReadWrite"

  # data disk details
  disk_data_size  = var.storage_details.disk_size
  disk_data_type  = var.storage_details.storage_account_type
  disk_data_iops  = var.storage_details.disk_iops_read_write
  disk_data_cache = "ReadWrite"

  # vm image
  vm_image_default = {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8_7"
    version   = "latest"
  }
  vm_image = var.vm_image != null ? var.vm_image : local.vm_image_default

  # vm user
  vm_default_user = "adminuser"
  vm_user         = var.vm_user != null ? var.vm_user : local.vm_default_user

  security_group_id = length(var.security_group_ids) == 0 ? azurerm_network_security_group.dsf_base_sg.id : var.security_group_ids[0]
}

resource "azurerm_public_ip" "vm_public_ip" {
  count = var.attach_persistent_public_ip ? 1 : 0
  name                = join("-", [var.name, "public", "ip"])
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

data "azurerm_public_ip" "vm_public_ip" {
  count = var.attach_persistent_public_ip ? 1 : 0
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
    caching              = local.disk_app_cache
    storage_account_type = local.disk_app_type
  }

  source_image_reference {
    publisher = local.vm_image.publisher
    offer     = local.vm_image.offer
    sku       = local.vm_image.sku
    version   = local.vm_image.version
  }

  identity {
    type = "SystemAssigned"
  }

  # Ignore changes to the custom_data attribute (Don't replace on userdata change)
  lifecycle {
    ignore_changes = [
      custom_data,
    ]
  }
}

data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "dsf_base_role_assignment" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Owner"
  principal_id         = azurerm_linux_virtual_machine.dsf_base_instance.identity[0].principal_id
}

# app disk
resource "azurerm_virtual_machine_data_disk_attachment" "app_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.external_app_vol.id
  virtual_machine_id = azurerm_linux_virtual_machine.dsf_base_instance.id
  lun                = "10"
  caching            = local.disk_app_cache
}

resource "azurerm_managed_disk" "external_app_vol" {
  name                 = join("-", [var.name, "app", "disk"])
  location             = var.resource_group.location
  resource_group_name  = var.resource_group.name
  storage_account_type = local.disk_app_type
  create_option        = "Empty"
  disk_size_gb         = local.disk_app_size
}

# data disk
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
}
