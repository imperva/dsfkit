locals {
  # vm user
  vm_default_user = "adminuser"
  vm_user         = var.vm_user != null ? var.vm_user : local.vm_default_user
}
