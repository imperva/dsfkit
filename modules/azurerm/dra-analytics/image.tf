locals {
  # vm user
  vm_default_user = "adminuser"
  vm_user         = var.vm_user != null ? var.vm_user : local.vm_default_user

  create_image_from_vhd = var.image_vhd_details.vhd != null ? true : false
  use_existing_image    = var.image_vhd_details.image != null ? true : false

  image_id = (local.use_existing_image ?
    "${data.azurerm_subscription.subscription.id}/resourceGroups/${var.image_vhd_details.image.resource_group_name}/providers/Microsoft.Compute/images/${var.image_vhd_details.image.image_id}" :
  "${azurerm_image.created_image[0].id}")
}

resource "azurerm_image" "created_image" {
  count = local.create_image_from_vhd ? 1 : 0

  name                = join("-", [var.name, "image"])
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  os_disk {
    os_type  = "Linux"
    caching  = "ReadWrite"
    os_state = "Generalized"
    blob_uri = "https://${var.image_vhd_details.vhd.storage_account_name}.blob.core.windows.net/${var.image_vhd_details.vhd.container_name}/${var.image_vhd_details.vhd.path_to_vhd}"
  }
  tags = var.tags
}
