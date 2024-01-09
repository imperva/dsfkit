locals {
  db_types = ["PostgreSql"]
  os_types = keys(local.os_params)

  db_type = var.db_type != null ? var.db_type : random_shuffle.db.result[0]
  os_type = "Ubuntu"

  vm_user           = local.os_params[local.os_type].vm_user
  security_group_id = length(var.security_group_ids) == 0 ? azurerm_network_security_group.dsf_agent_sg.id : var.security_group_ids[0]

  # root volume details
  root_volume_type  = "Standard_LRS"
  root_volume_cache = "ReadWrite"
}

resource "random_shuffle" "db" {
  input = local.db_types
}

resource "azurerm_linux_virtual_machine" "agent" {
  name                = var.friendly_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  size                = var.vm_instance_type
  admin_username      = local.vm_user

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = local.vm_user
    public_key = var.ssh_key.ssh_public_key
  }

  os_disk {
    caching              = local.root_volume_cache
    storage_account_type = local.root_volume_type
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agent.id]
  }

  source_image_reference {
    publisher = local.os_params[local.os_type].vm_image.publisher
    offer     = local.os_params[local.os_type].vm_image.offer
    sku       = local.os_params[local.os_type].vm_image.sku
    version   = local.os_params[local.os_type].vm_image.version
  }

  plan {
    publisher = local.os_params[local.os_type].vm_image.publisher
    product   = local.os_params[local.os_type].vm_image.offer
    name      = local.os_params[local.os_type].vm_image.sku
  }
  tags = merge(var.tags, { Name = join("-", [var.friendly_name]) })
  depends_on = [
    azurerm_role_assignment.agent_storage_role_assignment
  ]
}

resource "azurerm_user_assigned_identity" "agent" {
  name                = var.friendly_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
}

data "azurerm_subscription" "subscription" {
}

resource "azurerm_role_assignment" "agent_storage_role_assignment" {
  scope                = "${data.azurerm_subscription.subscription.id}/resourceGroups/${var.binaries_location.az_resource_group}/providers/Microsoft.Storage/storageAccounts/${var.binaries_location.az_storage_account}/blobServices/default/containers/${var.binaries_location.az_container}"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.agent.principal_id
}

resource "azurerm_network_interface" "nic" {
  name                = join("-", [var.friendly_name, "nic"])
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  ip_configuration {
    name                          = join("-", [var.friendly_name, "nic"])
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "nic_ip_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = local.security_group_id
}