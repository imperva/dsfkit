locals {
  # vm image
  version_parts           = split(".", var.dam_version)
  dam_major_version       = element(local.version_parts, 0)
  dam_azure_image_version = join(".", [element(local.version_parts, 0), element(local.version_parts, 1), element(local.version_parts, 3)])
  # The imperva-dam-v14 offer was removed from the Azure Marketplace; all DAM v14 images (LTS and non-LTS) are published under imperva-dam-v14-lts
  use_lts_offer = local.dam_major_version == "14"

  default_vm_image = {
    publisher = "imperva"
    offer     = join("", ["imperva-dam-v", local.dam_major_version, local.use_lts_offer ? "-lts" : ""])
    sku       = join("-", ["securesphere-imperva-dam", local.dam_major_version])
    version   = local.dam_azure_image_version
  }
  vm_image = var.vm_image != null ? var.vm_image : local.default_vm_image
}
