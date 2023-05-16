provider "aws" {
  region  = var.aws_region
}

module "globals" {
  source        = "../../../modules/aws/core/globals"
  sonar_version = var.sonar_version
  tags = local.tags
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  workstation_cidr_24 = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  web_console_admin_password = var.web_console_admin_password_secret_name != null ? null : (var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password)
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tarball_location           = var.tarball_location != null ? var.tarball_location : module.globals.tarball_location
  additional_tags            = var.additional_tags != null ? { for item in var.additional_tags : split("=", item)[0] => split("=", item)[1] } : {}
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted }, local.additional_tags)
  should_create_hub_key_pair = var.hub_key_pem_details == null ? true : false
  should_create_gw_key_pair  = var.gw_key_pem_details == null ? true : false
  admin_password_or_secret_name = var.web_console_admin_password_secret_name != null ? "See secret by the name of '${var.web_console_admin_password_secret_name}' in your AWS secret manager" : local.web_console_admin_password
}

##############################
# Generating ssh keys
##############################
module "key_pair_hub" {
  count                    = local.should_create_hub_key_pair ? 1 : 0
  source                   = "../../../modules/aws/core/key_pair"
  key_name_prefix          = "imperva-dsf-hub"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-hub-${terraform.workspace}"
  tags = local.tags
}

module "key_pair_gw" {
  count                    = local.should_create_gw_key_pair ? 1 : 0
  source                   = "../../../modules/aws/core/key_pair"
  key_name_prefix          = "imperva-dsf-gw"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw-${terraform.workspace}"
  tags = local.tags
}

locals {
  hub_private_key_pem_file_path = var.hub_key_pem_details != null ? var.hub_key_pem_details.private_key_pem_file_path : module.key_pair_hub[0].private_key_file_path
  hub_public_key_name           = var.hub_key_pem_details != null ? var.hub_key_pem_details.public_key_name : module.key_pair_hub[0].key_pair.key_pair_name
  gw_private_key_pem_file_path  = var.gw_key_pem_details != null ? var.gw_key_pem_details.private_key_pem_file_path : module.key_pair_gw[0].private_key_file_path
  gw_public_key_name            = var.gw_key_pem_details != null ? var.gw_key_pem_details.public_key_name : module.key_pair_gw[0].key_pair.key_pair_name
}

data "aws_subnet" "subnet_gw" {
  id = var.subnet_gw
}

##############################
# Generating deployment
##############################
module "hub_primary" {
  source                     = "../../../modules/aws/hub"
  friendly_name              = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                  = var.subnet_hub
  security_group_id          = var.security_group_id_hub
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  web_console_admin_password_secret_name = var.web_console_admin_password_secret_name
  instance_type              = var.hub_instance_type
  ebs                        = var.hub_ebs_details
  attach_public_ip           = false
  ami                        = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_private_key_pem_file_path
    ssh_public_key_name       = local.hub_public_key_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = concat(local.workstation_cidr, ["${module.hub_secondary.private_ip}/32"], [data.aws_subnet.subnet_gw.cidr_block])
  }
  use_public_ip                     = false
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  internal_private_key_secret_name = var.internal_hub_private_key_secret_name
  internal_public_key = try(trimspace(file(var.internal_hub_public_key_file_path)), "")
  tags = local.tags
}

module "hub_secondary" {
  source                     = "../../../modules/aws/hub"
  friendly_name              = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                  = var.subnet_hub_secondary
  security_group_id          = var.security_group_id_hub
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  web_console_admin_password_secret_name = var.web_console_admin_password_secret_name
  instance_type              = var.hub_instance_type
  ebs                        = var.hub_ebs_details
  attach_public_ip           = false
  ami                        = var.ami
  hadr_secondary_node        = true
  sonarw_public_key          = module.hub_primary.sonarw_public_key
  sonarw_private_key         = module.hub_primary.sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_private_key_pem_file_path
    ssh_public_key_name       = local.hub_public_key_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = concat(local.workstation_cidr, ["${module.hub_primary.private_ip}/32"], [data.aws_subnet.subnet_gw.cidr_block])
  }
  use_public_ip                     = false
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  internal_private_key_secret_name = var.internal_hub_private_key_secret_name
  internal_public_key = try(trimspace(file(var.internal_hub_public_key_file_path)), "")
  tags = local.tags
}

module "agentless_gw_group" {
  count                      = var.gw_count
  source                     = "../../../modules/aws/agentless-gw"
  friendly_name              = join("-", [local.deployment_name_salted, "gw", count.index])
  subnet_id                  = var.subnet_gw
  security_group_id          = var.security_group_id_gw
  instance_type              = var.gw_instance_type
  ebs                        = var.gw_group_ebs_details
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  web_console_admin_password_secret_name = var.web_console_admin_password_secret_name
  hub_sonarw_public_key      = module.hub_primary.sonarw_public_key
  attach_public_ip           = false
  ami                        = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.gw_private_key_pem_file_path
    ssh_public_key_name       = local.gw_public_key_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub_primary.private_ip}/32", "${module.hub_secondary.private_ip}/32"])
  }
  use_public_ip = false
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_primary.private_ip
    proxy_private_ssh_key_path = local.hub_private_key_pem_file_path
    proxy_ssh_user             = module.hub_primary.ssh_user
  }
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  internal_private_key_secret_name = var.internal_gw_private_key_secret_name
  internal_public_key = try(trimspace(file(var.internal_gw_public_key_file_path)), "")
  tags = local.tags
}

module "hub_hadr" {
  source                       = "../../../modules/null/hadr"
  sonar_version                = module.globals.tarball_location.version
  dsf_primary_ip               = module.hub_primary.private_ip
  dsf_primary_private_ip       = module.hub_primary.private_ip
  dsf_secondary_ip             = module.hub_secondary.private_ip
  dsf_secondary_private_ip     = module.hub_secondary.private_ip
  ssh_key_path                 = local.hub_private_key_pem_file_path
  ssh_user                     = module.hub_primary.ssh_user
  terraform_script_path_folder = var.terraform_script_path_folder
  depends_on = [
    module.hub_primary,
    module.hub_secondary
  ]
}

locals {
  hub_gw_combinations = setproduct(
    [module.hub_primary, module.hub_secondary],
    concat(
      [for idx, val in module.agentless_gw_group : val]
    )
  )
}

module "federation" {
  count   = length(local.hub_gw_combinations)
  source  = "../../../modules/null/federation"
  gw_info = {
    gw_ip_address           = local.hub_gw_combinations[count.index][1].private_ip
    gw_private_ssh_key_path = local.gw_private_key_pem_file_path
    gw_ssh_user             = local.hub_gw_combinations[count.index][1].ssh_user
  }
  hub_info = {
    hub_ip_address           = local.hub_gw_combinations[count.index][0].private_ip
    hub_private_ssh_key_path = local.hub_private_key_pem_file_path
    hub_ssh_user             = local.hub_gw_combinations[count.index][0].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_primary.private_ip
    proxy_private_ssh_key_path = local.hub_private_key_pem_file_path
    proxy_ssh_user             = module.hub_primary.ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_group
  ]
}
