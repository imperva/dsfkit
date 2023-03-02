provider "aws" {
  default_tags {
    tags = local.tags
  }
  profile = var.aws_profile_hub
  region  = var.aws_region_hub
}

provider "aws" {
  default_tags {
    tags = local.tags
  }
  profile = var.aws_profile_gw
  region  = var.aws_region_gw
  alias   = "gw"
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.3.7" # latest release tag
  sonar_version = var.sonar_version
}

locals {
  workstation_cidr_24 = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
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

module "key_pair_gw" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.7" # latest release tag
  key_name_prefix          = "imperva-dsf-gw"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw-${terraform.workspace}"
  providers = {
    aws = aws.gw
  }
}

##############################
# Generating deployment
##############################

module "hub" {
  source                     = "imperva/dsf-hub/aws"
  version                    = "1.3.7" # latest release tag
  friendly_name              = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                  = var.subnet_hub
  security_group_id          = var.security_group_id_hub
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  ebs                        = var.hub_ebs_details
  attach_pubilc_ip           = false
  instance_type              = var.hub_instance_type
  ami                        = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_hub.key_pair_private_pem.filename
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

module "agentless_gw_group" {
  count                      = var.gw_count
  source                     = "imperva/dsf-agentless-gw/aws"
  version                    = "1.3.7" # latest release tag
  friendly_name              = join("-", [local.deployment_name_salted, "gw", count.index])
  instance_type              = var.gw_instance_type
  ami                        = var.ami
  subnet_id                  = var.subnet_gw
  security_group_id          = var.security_group_id_gw
  ebs                        = var.gw_group_ebs_details
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  hub_sonarw_public_key      = module.hub.sonarw_public_key
  attach_pubilc_ip           = false
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_gw.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair_gw.key_pair.key_pair_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub.private_ip}/32"])
  }
  use_public_ip = false
  ingress_communication_via_proxy = {
    proxy_address              = module.hub.private_ip
    proxy_private_ssh_key_path = module.key_pair_hub.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  depends_on = [
    module.hub
  ]
  providers = {
    aws = aws.gw
  }
}

module "federation" {
  for_each = { for idx, val in module.agentless_gw_group : idx => val }
  source   = "imperva/dsf-federation/null"
  version  = "1.3.7" # latest release tag
  gw_info = {
    gw_ip_address           = each.value.private_ip
    gw_private_ssh_key_path = module.key_pair_gw.key_pair_private_pem.filename
    gw_ssh_user             = each.value.ssh_user
  }
  hub_info = {
    hub_ip_address           = module.hub.private_ip
    hub_private_ssh_key_path = module.key_pair_hub.key_pair_private_pem.filename
    hub_ssh_user             = module.hub.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub.private_ip
    proxy_private_ssh_key_path = module.key_pair_hub.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.hub,
    module.agentless_gw_group,
  ]
}
