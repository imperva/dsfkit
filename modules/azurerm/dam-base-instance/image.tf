locals {
  # vm image
  version_parts = split(".", var.dam_version)
  dam_major_version = element(local.version_parts, 0)
  dam_azure_image_version   = join(".", [element(local.version_parts, 0), element(local.version_parts, 1), element(local.version_parts, 3)])
  is_lts_version = startswith(var.dam_version, "14.7.")

  default_vm_image =  {
    publisher = "imperva"
    offer     = join("", ["imperva-dam-v", local.dam_major_version, local.is_lts_version? "-lts" : ""])
    sku       = join("-", ["securesphere-imperva-dam", local.dam_major_version])
    version   = local.dam_azure_image_version
  }
  vm_image = var.vm_image != null ? var.vm_image : local.default_vm_image
}
