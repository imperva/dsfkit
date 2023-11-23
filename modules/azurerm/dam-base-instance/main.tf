locals {
  public_ip  = azurerm_linux_virtual_machine.dsf_base_instance.public_ip_address
  private_ip = azurerm_linux_virtual_machine.dsf_base_instance.private_ip_address

  # root volume details
  root_volume_size  = 160
  root_volume_type  = "Standard_LRS"
  root_volume_cache = "ReadWrite"

  security_group_id = length(var.security_group_ids) == 0 ? azurerm_network_security_group.dsf_base_sg.id : var.security_group_ids[0]

  mapper = {
    # TODO sivan - decide instance types
    instance_type = {
      AV2500 = "Standard_E4s_v5",
      AV6500 = "Standard_E4s_v5",
      AVM150 = "Standard_E4s_v5"
    }
    product_role = {
      mx       = "server",
      agent-gw = "gateway"
    }
  }
}


# TODO sivan - storage?

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

resource "azurerm_linux_virtual_machine" "dsf_base_instance" {
  name                = var.name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  size                = local.mapper.instance_type[var.dam_model]
  admin_username      = var.vm_user

#  custom_data = base64encode(local.userdata)

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.vm_user
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

  plan {
    publisher = local.vm_image.publisher
    product   = local.vm_image.offer
    name      = local.vm_image.sku
  }

  # TODO sivan - ask Eytan
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
}

resource "azurerm_user_assigned_identity" "dsf_base" {
  name                = var.name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
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

resource "azurerm_network_interface_security_group_association" "nic_ip_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = local.security_group_id
}