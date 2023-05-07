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
  version       = "1.4.4" # latest release tag
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
  should_create_hub_key_pair = var.hub_key_pem_details == null ? true : false
  should_create_gw_key_pair  = var.gw_key_pem_details == null ? true : false
}

##############################
# Generating ssh keys
##############################

module "key_pair_hub" {
  count                    = local.should_create_hub_key_pair ? 1 : 0
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.4" # latest release tag
  key_name_prefix          = "imperva-dsf-hub"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-hub-${terraform.workspace}"
}

module "key_pair_gw" {
  count                    = local.should_create_gw_key_pair ? 1 : 0
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.4" # latest release tag
  key_name_prefix          = "imperva-dsf-gw"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw-${terraform.workspace}"
  providers = {
    aws = aws.gw
  }
}

locals {
  hub_private_key_pem_file_path = var.hub_key_pem_details != null ? var.hub_key_pem_details.private_key_pem_file_path : module.key_pair_hub[0].private_key_file_path
  hub_public_key_name           = var.hub_key_pem_details != null ? var.hub_key_pem_details.public_key_name : module.key_pair_hub[0].key_pair.key_pair_name
  gw_private_key_pem_file_path  = var.gw_key_pem_details != null ? var.gw_key_pem_details.private_key_pem_file_path : module.key_pair_gw[0].private_key_file_path
  gw_public_key_name            = var.gw_key_pem_details != null ? var.gw_key_pem_details.public_key_name : module.key_pair_gw[0].key_pair.key_pair_name
}

data "aws_subnet" "subnet_hub" {
  id       = var.subnet_hub
}

data "aws_subnet" "subnet_gw" {
  id       = var.subnet_gw
  provider = aws.gw
}

##############################
# Generating deployment
##############################

module "hub" {
  source                     = "imperva/dsf-hub/aws"
  version                    = "1.4.4" # latest release tag
  friendly_name              = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                  = var.subnet_hub
  security_group_ids         = var.security_group_ids_hub
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  ebs                        = var.hub_ebs_details
  instance_type              = var.hub_instance_type
  ami                        = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_private_key_pem_file_path
    ssh_public_key_name       = local.hub_public_key_name
  }
  allowed_web_console_cidrs = var.web_console_cidr
  allowed_agentless_gw_cidrs = [data.aws_subnet.subnet_gw.cidr_block]
  allowed_all_cidrs = local.workstation_cidr

  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
}

module "agentless_gw_group" {
  count                      = var.gw_count
  source                     = "imperva/dsf-agentless-gw/aws"
  version                    = "1.4.4" # latest release tag
  friendly_name              = join("-", [local.deployment_name_salted, "gw", count.index])
  instance_type              = var.gw_instance_type
  ami                        = var.ami
  subnet_id                  = var.subnet_gw
  security_group_ids          = var.security_group_ids_gw
  ebs                        = var.gw_group_ebs_details
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  hub_sonarw_public_key      = module.hub.sonarw_public_key
  ssh_key_pair = {
    ssh_private_key_file_path = local.gw_private_key_pem_file_path
    ssh_public_key_name       = local.gw_public_key_name
  }
  allowed_hub_cidrs = [data.aws_subnet.subnet_hub.cidr_block]
  allowed_all_cidrs = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub.private_ip
    proxy_private_ssh_key_path = local.hub_private_key_pem_file_path
    proxy_ssh_user             = module.hub.ssh_user
  }
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  providers = {
    aws = aws.gw
  }
}

module "federation" {
  for_each = { for idx, val in module.agentless_gw_group : idx => val }
  source   = "imperva/dsf-federation/null"
  version  = "1.4.4" # latest release tag
  gw_info = {
    gw_ip_address           = each.value.private_ip
    gw_private_ssh_key_path = local.gw_private_key_pem_file_path
    gw_ssh_user             = each.value.ssh_user
  }
  hub_info = {
    hub_ip_address           = module.hub.private_ip
    hub_private_ssh_key_path = local.hub_private_key_pem_file_path
    hub_ssh_user             = module.hub.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub.private_ip
    proxy_private_ssh_key_path = local.hub_private_key_pem_file_path
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.hub,
    module.agentless_gw_group,
  ]
}
