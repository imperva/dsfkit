locals {
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
}
