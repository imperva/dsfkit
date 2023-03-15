provider "aws" {
  default_tags {
    tags = local.tags
  }
  region  = var.aws_region_gw1
}

provider "aws" {
  default_tags {
    tags = local.tags
  }
  region  = var.aws_region_gw2
  alias = "gw2"
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
  workstation_cidr_24        = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}

##############################
# Generating ssh keys
##############################
module "key_pair_gw1" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.7" # latest release tag
  key_name_prefix          = "imperva-dsf-gw1"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw1-${terraform.workspace}"
}

module "key_pair_gw2" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.7" # latest release tag
  key_name_prefix          = "imperva-dsf-gw2"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw2-${terraform.workspace}"
  providers = {
    aws = aws.gw2
  }
}

##############################
# Generating deployment
##############################
module "agentless_gw1_group" {
  count                      = var.gw_count
  source                     = "imperva/dsf-agentless-gw/aws"
  version                    = "1.3.7" # latest release tag
  friendly_name              = join("-", [local.deployment_name_salted, "gw1", count.index])
  subnet_id                  = var.subnet_gw1
  security_group_id          = var.security_group_id_gw1
  instance_type              = var.gw_instance_type
  ebs                        = var.gw_group_ebs_details
  binaries_location          = module.globals.tarball_location
  web_console_admin_password = local.web_console_admin_password
  hub_sonarw_public_key      = var.hub_sonarw_public_key
  attach_public_ip           = false
  ami                        = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_gw1.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair_gw1.key_pair.key_pair_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${var.hub_private_ip}/32"])
  }
  use_public_ip = false
  ingress_communication_via_proxy = {
    proxy_address              = var.hub_private_ip
    proxy_private_ssh_key_path = var.hub_private_key_pem_file_path
    proxy_ssh_user             = var.hub_ssh_user
  }
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
}

module "agentless_gw2_group" {
  count                      = var.gw_count
  source                     = "imperva/dsf-agentless-gw/aws"
  version                    = "1.3.7" # latest release tag
  friendly_name              = join("-", [local.deployment_name_salted, "gw2", count.index])
  subnet_id                  = var.subnet_gw2
  security_group_id          = var.security_group_id_gw2
  instance_type              = var.gw_instance_type
  ebs                        = var.gw_group_ebs_details
  binaries_location          = module.globals.tarball_location
  web_console_admin_password = local.web_console_admin_password
  hub_sonarw_public_key      = var.hub_sonarw_public_key
  attach_public_ip           = false
  ami                        = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_gw2.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair_gw2.key_pair.key_pair_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${var.hub_private_ip}/32"])
  }
  use_public_ip = false
  ingress_communication_via_proxy = {
    proxy_address              = var.hub_private_ip
    proxy_private_ssh_key_path = var.hub_private_key_pem_file_path
    proxy_ssh_user             = var.hub_ssh_user
  }
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  providers = {
    aws = aws.gw2
  }
}

locals {
  hub_gws_combinations = setproduct(
    [{private_ip: var.hub_private_ip, private_key_pem_file_path: var.hub_private_key_pem_file_path, ssh_user: var.hub_ssh_user}],
    concat(
      [for idx, val in module.agentless_gw1_group : {private_ip: val.private_ip, private_key_pem_file_path: module.key_pair_gw1.key_pair_private_pem.filename, ssh_user: val.ssh_user}],
      [for idx, val in module.agentless_gw2_group : {private_ip: val.private_ip, private_key_pem_file_path: module.key_pair_gw2.key_pair_private_pem.filename, ssh_user: val.ssh_user}]
    )
  )
}

module "federation_gws" {
  count                     = length(local.hub_gws_combinations)
  source                    = "imperva/dsf-federation/null"
  version                   = "1.3.7" # latest release tag
  gw_info = {
    gw_ip_address           = local.hub_gws_combinations[count.index][1].private_ip
    gw_private_ssh_key_path = local.hub_gws_combinations[count.index][1].private_key_pem_file_path
    gw_ssh_user             = local.hub_gws_combinations[count.index][1].ssh_user
  }
  hub_info = {
    hub_ip_address           = local.hub_gws_combinations[count.index][0].private_ip
    hub_private_ssh_key_path = local.hub_gws_combinations[count.index][0].private_key_pem_file_path
    hub_ssh_user             = local.hub_gws_combinations[count.index][0].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = var.hub_private_ip
    proxy_private_ssh_key_path = var.hub_private_key_pem_file_path
    proxy_ssh_user             = var.hub_ssh_user
  }
  depends_on = [
    module.agentless_gw1_group,
    module.agentless_gw2_group
  ]
}
