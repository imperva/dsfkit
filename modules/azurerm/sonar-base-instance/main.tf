locals {
  disk_app_size   = 100
  disk_app_type   = "Standard_LRS"
  disk_app_cache  = "ReadWrite"
  disk_data_size  = 1000
  disk_data_type  = "Standard_LRS"
  disk_data_cache = "ReadWrite"
  # tbd: add iops and more important attributes like throughput
  # ebs_state_disk_type  = "gp3"
  # ebs_state_disk_size  = var.ebs_details.disk_size
  # ebs_state_iops       = var.ebs_details.provisioned_iops
  # ebs_state_throughput = var.ebs_details.throughput
  #tbd: pass ami params from outside
  #   ami_name_default = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2" # Exists on all regions
  #   ami_name         = var.ami_name_tag != null ? var.ami_name_tag : local.ami_name_default
  admin_user_default = "adminuser"
  #   ami_user         = var.ami_user != null ? var.ami_user : local.ami_user_default
}

resource "azurerm_linux_virtual_machine" "dsf_base_instance" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = var.instance_type
  admin_username      = local.admin_user_default

  custom_data = base64encode(local.install_script)

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
    username   = local.admin_user_default
    public_key = var.public_ssh_key
  }

  os_disk {
    caching              = local.disk_app_cache
    storage_account_type = local.disk_app_type
    disk_size_gb         = local.disk_app_size
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8_7" # "7_9"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
  #tbd pass tags as params for all resources
  #tbd disable_api_termination
}

data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "dsf_base_role_assignment" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Owner" # tbd: set minimal role
  principal_id         = azurerm_linux_virtual_machine.dsf_base_instance.identity[0].principal_id
}

resource "azurerm_managed_disk" "external_data_vol" {
  name                 = join("-", [var.name, "data", "volume", "ebs"])
  location             = var.resource_group_location
  resource_group_name  = var.resource_group_name
  storage_account_type = local.disk_data_type
  create_option        = "Empty"
  disk_size_gb         = local.disk_data_size
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.external_data_vol.id
  virtual_machine_id = azurerm_linux_virtual_machine.dsf_base_instance.id
  lun                = "10"
  caching            = local.disk_data_cache
}

resource "azurerm_public_ip" "example" {
  count               = var.create_and_attach_public_elastic_ip ? 1 : 0
  name                = join("-", [var.name, "public", "ip"])
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

data "azurerm_public_ip" "example" {
  count               = var.create_and_attach_public_elastic_ip ? 1 : 0
  name                = join("-", [var.name, "public", "ip"])
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_linux_virtual_machine.dsf_base_instance
  ]
}

resource "azurerm_network_interface" "example" {
  name                = join("-", [var.name, "nic"])
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = join("-", [var.name, "nic"])
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.example[0].id, null)
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.dsf_base_sg.id
}
