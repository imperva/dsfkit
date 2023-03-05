provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.3.7" # latest release tag
  sonar_version = var.sonar_version
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr_24        = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tarball_location           = var.tarball_location != null ? var.tarball_location : module.globals.tarball_location
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}

##############################
# Generating ssh keys
##############################
module "key_pair_hub" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.7" # latest release tag
  key_name_prefix          = "imperva-dsf-hub"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-hub-${terraform.workspace}"
}

##############################
# Generating deployment
##############################
module "hub" {
  source                              = "imperva/dsf-hub/aws"
  version                             = "1.3.7" # latest release tag
  friendly_name                       = join("-", [local.deployment_name_salted, "hub"])
  subnet_id                           = var.subnet_hub
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  instance_type                       = var.hub_instance_type
  ebs                                 = var.hub_ebs_details
  create_and_attach_public_elastic_ip = true
  ami                                 = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_hub.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair_hub.key_pair.key_pair_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = local.workstation_cidr
    use_public_ip                           = true
  }
  skip_instance_health_verification   = var.hub_skip_instance_health_verification
  terraform_script_path_folder        = var.terraform_script_path_folder
}
