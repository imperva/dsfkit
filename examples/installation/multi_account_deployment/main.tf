module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.4.4" # latest release tag
  sonar_version = var.sonar_version
}

locals {
  workstation_cidr_24        = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
  deployment_name_salted     = join("-", [var.deployment_name, module.globals.salt])
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

module "key_pair_hub_secondary" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.4" # latest release tag
  key_name_prefix          = "imperva-dsf-hub-secondary"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-hub-secondary-${terraform.workspace}"
  providers = {
    aws = aws.hub-secondary
  }
}

module "key_pair_gw" {
  count                    = local.should_create_gw_key_pair ? 1 : 0
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.4" # latest release tag
  key_name_prefix          = "imperva-dsf-gw"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw-${terraform.workspace}"
  providers = {
    aws = aws.gw-primary
  }
}

module "key_pair_gw_secondary" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.4" # latest release tag
  key_name_prefix          = "imperva-dsf-gw-secondary"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw-secondary-${terraform.workspace}"
  providers = {
    aws = aws.gw-secondary
  }
}

data "aws_subnet" "subnet_gw_primary" {
  id = var.subnet_gw_primary
  provider = aws.gw-primary
}

data "aws_subnet" "subnet_gw_secondary" {
  id = var.subnet_gw_secondary
  provider = aws.gw-secondary
}

locals {
  hub_private_key_pem_file_path = var.hub_key_pem_details != null ? var.hub_key_pem_details.private_key_pem_file_path : module.key_pair_hub[0].private_key_file_path
  hub_public_key_name           = var.hub_key_pem_details != null ? var.hub_key_pem_details.public_key_name : module.key_pair_hub[0].key_pair.key_pair_name
  gw_private_key_pem_file_path  = var.gw_key_pem_details != null ? var.gw_key_pem_details.private_key_pem_file_path : module.key_pair_gw[0].private_key_file_path
  gw_public_key_name            = var.gw_key_pem_details != null ? var.gw_key_pem_details.public_key_name : module.key_pair_gw[0].key_pair.key_pair_name
  gws_cidr_list                 = [data.aws_subnet.subnet_gw_primary.cidr_block, data.aws_subnet.subnet_gw_secondary.cidr_block]
}

##############################
# Generating deployment
##############################
module "hub_primary" {
  source                      = "imperva/dsf-hub/aws"
  version                     = "1.4.4" # latest release tag
  friendly_name               = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                   = var.subnet_hub_primary
  security_group_id           = var.security_group_id_hub_primary
  binaries_location           = local.tarball_location
  web_console_admin_password  = local.web_console_admin_password
  instance_type               = var.hub_instance_type
  ebs                         = var.hub_ebs_details
  attach_public_ip            = false
  ami                         = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_hub.private_key_file_path
    ssh_public_key_name       = module.key_pair_hub.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_all_cidrs = concat(local.workstation_cidr, ["${module.hub_secondary.private_ip}/32", "${var.proxy_private_address}/32"], local.gws_cidr_list)
  use_public_ip                     = false
  ingress_communication_via_proxy = {
    proxy_address                 = var.proxy_address
    proxy_private_ssh_key_path    = var.proxy_ssh_key_path
    proxy_ssh_user                = var.proxy_ssh_user
  }
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
}

module "hub_secondary" {
  source                      = "imperva/dsf-hub/aws"
  version                     = "1.4.4" # latest release tag
  friendly_name               = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                   = var.subnet_hub_secondary
  security_group_id           = var.security_group_id_hub_secondary
  binaries_location           = local.tarball_location
  web_console_admin_password  = local.web_console_admin_password
  instance_type               = var.hub_instance_type
  ebs                         = var.hub_ebs_details
  attach_public_ip            = false
  ami                         = var.ami
  hadr_secondary_node         = true
  sonarw_public_key           = module.hub_primary.sonarw_public_key
  sonarw_private_key          = module.hub_primary.sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_hub_secondary.private_key_file_path
    ssh_public_key_name       = module.key_pair_hub_secondary.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_all_cidrs = concat(local.workstation_cidr, ["${module.hub_primary.private_ip}/32", "${var.proxy_private_address}/32"], local.gws_cidr_list)
  use_public_ip               = false
  ingress_communication_via_proxy = {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  }
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  providers = {
    aws = aws.hub-secondary
  }
}

module "agentless_gw_group_primary" {
  count                       = var.gw_count
  source                      = "imperva/dsf-agentless-gw/aws"
  version                     = "1.4.4" # latest release tag
  friendly_name               = join("-", [local.deployment_name_salted, "gw", count.index, "primary"])
  subnet_id                   = var.subnet_gw_primary
  security_group_ids          = var.security_group_ids_gw
  instance_type               = var.gw_instance_type
  ebs                         = var.gw_group_ebs_details
  binaries_location           = local.tarball_location
  web_console_admin_password  = local.web_console_admin_password
  hub_sonarw_public_key       = module.hub_primary.sonarw_public_key
  attach_public_ip            = false
  ami                         = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_gw.private_key_file_path
    ssh_public_key_name       = module.key_pair_gw.key_pair.key_pair_name
  }
  allowed_hub_cidrs = [data.aws_subnet.subnet_hub.cidr_block]
#  full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub_primary.private_ip}/32", "${module.hub_secondary.private_ip}/32", "${var.proxy_private_address}/32"], [data.aws_subnet.subnet_gw_secondary.cidr_block])
  allowed_all_cidrs = local.workstation_cidr
  use_public_ip               = false
  ingress_communication_via_proxy = {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  }
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  providers = {
    aws = aws.gw-primary
  }
}

module "agentless_gw_group_secondary" {
  count                       = var.gw_count
  source                      = "imperva/dsf-agentless-gw/aws"
  version                     = "1.4.4" # latest release tag
  friendly_name               = join("-", [local.deployment_name_salted, "gw", count.index, "secondary"])
  subnet_id                   = var.subnet_gw_secondary
  security_group_id           = var.security_group_id_gw_secondary
  instance_type               = var.gw_instance_type
  ebs                         = var.gw_group_ebs_details
  binaries_location           = local.tarball_location
  web_console_admin_password  = local.web_console_admin_password
  hub_sonarw_public_key       = module.hub_primary.sonarw_public_key
  hadr_secondary_node         = true
  sonarw_public_key           = module.agentless_gw_group_primary[count.index].sonarw_public_key
  sonarw_private_key          = module.agentless_gw_group_primary[count.index].sonarw_private_key
  attach_public_ip            = false
  ami                         = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_gw_secondary.private_key_file_path
    ssh_public_key_name       = module.key_pair_gw_secondary.key_pair.key_pair_name
  }
  allowed_hub_cidrs = [data.aws_subnet.subnet_hub.cidr_block]
  full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub_primary.private_ip}/32", "${module.hub_secondary.private_ip}/32", "${var.proxy_private_address}/32"], [data.aws_subnet.subnet_gw_primary.cidr_block])
  allowed_all_cidrs = local.workstation_cidr
  use_public_ip               = false
  ingress_communication_via_proxy = {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  }
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  providers = {
    aws = aws.gw-secondary
  }
}

module "hub_hadr" {
  source                   = "imperva/dsf-hadr/null"
  version                  = "1.4.4" # latest release tag
  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.hub_primary.private_ip
  dsf_primary_private_ip   = module.hub_primary.private_ip
  dsf_secondary_ip         = module.hub_secondary.private_ip
  dsf_secondary_private_ip = module.hub_secondary.private_ip
  ssh_key_path             = module.key_pair_hub.private_key_file_path
  ssh_key_path_secondary   = module.key_pair_hub_secondary.private_key_file_path
  ssh_user                 = module.hub_primary.ssh_user
  ssh_user_secondary       = module.hub_secondary.ssh_user
  proxy_info = {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  }
  depends_on = [
    module.hub_primary,
    module.hub_secondary
  ]
}

module "agentless_gw_group_hadr" {
  count                        = var.gw_count
  source                       = "imperva/dsf-hadr/null"
  version                      = "1.4.4" # latest release tag
  sonar_version                = module.globals.tarball_location.version
  dsf_primary_ip               = module.agentless_gw_group_primary[count.index].private_ip
  dsf_primary_private_ip       = module.agentless_gw_group_primary[count.index].private_ip
  dsf_secondary_ip             = module.agentless_gw_group_secondary[count.index].private_ip
  dsf_secondary_private_ip     = module.agentless_gw_group_secondary[count.index].private_ip
  ssh_key_path                 = module.key_pair_gw.private_key_file_path
  ssh_key_path_secondary       = module.key_pair_gw_secondary.private_key_file_path
  ssh_user                     = module.agentless_gw_group_primary[count.index].ssh_user
  ssh_user_secondary           = module.agentless_gw_group_secondary[count.index].ssh_user
  proxy_info = {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  }
  depends_on = [
    module.agentless_gw_group_primary,
    module.agentless_gw_group_secondary
  ]
}

locals {
  hub_gws_combinations = setproduct(
    [{instance: module.hub_primary, keypair: module.key_pair_hub}, {instance: module.hub_secondary, keypair: module.key_pair_hub_secondary}],
    concat(
      [for idx, val in module.agentless_gw_group_primary : {instance: val, keypair: module.key_pair_gw}],
      [for idx, val in module.agentless_gw_group_secondary : {instance: val, keypair: module.key_pair_gw_secondary}]
    )
  )
}

module "federation_gws" {
  count                     = length(local.hub_gws_combinations)
  source                    = "imperva/dsf-federation/null"
  version                   = "1.4.4" # latest release tag
  gw_info = {
    gw_ip_address           = local.hub_gws_combinations[count.index][1].instance.private_ip
    gw_private_ssh_key_path = local.hub_gws_combinations[count.index][1].keypair.private_key_file_path
    gw_ssh_user             = local.hub_gws_combinations[count.index][1].instance.ssh_user
  }
  hub_info = {
    hub_ip_address           = local.hub_gws_combinations[count.index][0].instance.private_ip
    hub_private_ssh_key_path = local.hub_gws_combinations[count.index][0].keypair.private_key_file_path
    hub_ssh_user             = local.hub_gws_combinations[count.index][0].instance.ssh_user
  }
  hub_proxy_info = {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  }
  gw_proxy_info = {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_group_hadr
  ]
}
