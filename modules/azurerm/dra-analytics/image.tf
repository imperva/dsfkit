locals {
  # vm user
  vm_default_user = "adminuser"
  vm_user         = var.vm_user != null ? var.vm_user : local.vm_default_user

  create_image_from_vhd = var.vhd_details != null ? true : false
  use_existing_image = var.image_details != null ? true : false

  image_id = (local.use_existing_image ?
    "${data.azurerm_subscription.subscription.id}/resourceGroups/${var.image_details.resource_group_name}/providers/Microsoft.Compute/images/${var.image_details.image_id}" :
    "${azurerm_image.created_image[0].id}")
}

resource "azurerm_image" "created_image" {
  count               = local.create_image_from_vhd ? 1 : 0

  name                = join("-", [var.name, "image"])
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  os_disk {
    os_type = "Linux"
    caching = "ReadWrite"
    os_state = "Generalized"
    blob_uri = "https://${var.vhd_details.storage_account_name}.blob.core.windows.net/${var.vhd_details.container_name}/${var.vhd_details.path_to_vhd}"
  }
  tags = var.tags
}
