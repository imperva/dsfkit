provider "aws" {
  default_tags {
    tags = local.tags
  }
  region  = var.aws_region_hub
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.3.10" # latest release tag
  sonar_version = var.sonar_version
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  workstation_cidr_24        = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}

##############################
# Generating ssh keys
##############################
module "key_pair_hub" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.10" # latest release tag
  key_name_prefix          = "imperva-dsf-hub"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-hub-${terraform.workspace}"
}

##############################
# Generating deployment
##############################
module "hub_primary" {
  source                     = "imperva/dsf-hub/aws"
  version                    = "1.3.10" # latest release tag
  friendly_name              = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                  = var.subnet_hub
  security_group_id          = var.security_group_id_hub
  binaries_location          = module.globals.tarball_location
  web_console_admin_password = local.web_console_admin_password
  instance_type              = var.hub_instance_type
  ebs                        = var.hub_ebs_details
  attach_public_ip           = false
  ami                        = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_hub.private_key_file_path
    ssh_public_key_name       = module.key_pair_hub.key_pair.key_pair_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = local.workstation_cidr
  }
  use_public_ip                     = false
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
}
