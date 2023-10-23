module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.5.6" # latest release tag
  sonar_version = var.sonar_version
}

locals {
  workstation_cidr_24             = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
  deployment_name_salted          = join("-", [var.deployment_name, module.globals.salt])
  password                        = var.password != null ? var.password : module.globals.random_password
  workstation_cidr                = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tarball_location                = var.tarball_location != null ? var.tarball_location : module.globals.tarball_location
  additional_tags                 = var.additional_tags != null ? { for item in var.additional_tags : split("=", item)[0] => split("=", item)[1] } : {}
  tags                            = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted }, local.additional_tags)
  should_create_hub_main_key_pair = var.hub_main_key_pair == null ? true : false
  should_create_hub_dr_key_pair   = var.hub_dr_key_pair == null ? true : false
  should_create_gw_main_key_pair  = var.gw_main_key_pair == null ? true : false
  should_create_gw_dr_key_pair    = var.gw_dr_key_pair == null ? true : false
}

##############################
# Generating ssh keys
##############################

module "key_pair_hub_main" {
  count                = local.should_create_hub_main_key_pair ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.6" # latest release tag
  key_name_prefix      = "imperva-dsf-hub-main"
  private_key_filename = "ssh_keys/dsf_ssh_key-hub-main-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.hub-main
  }
}

module "key_pair_hub_dr" {
  count                = local.should_create_hub_dr_key_pair ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.6" # latest release tag
  key_name_prefix      = "imperva-dsf-hub-dr"
  private_key_filename = "ssh_keys/dsf_ssh_key-hub-dr-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.hub-dr
  }
}

module "key_pair_gw_main" {
  count                = local.should_create_gw_main_key_pair ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.6" # latest release tag
  key_name_prefix      = "imperva-dsf-gw"
  private_key_filename = "ssh_keys/dsf_ssh_key-gw-main-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.gw-main
  }
}

module "key_pair_gw_dr" {
  count                = local.should_create_gw_dr_key_pair ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.6" # latest release tag
  key_name_prefix      = "imperva-dsf-gw-dr"
  private_key_filename = "ssh_keys/dsf_ssh_key-gw-dr-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.gw-dr
  }
}

data "aws_subnet" "subnet_hub_main" {
  id       = var.subnet_hub_main
  provider = aws.hub-main
}

data "aws_subnet" "subnet_hub_dr" {
  id       = var.subnet_hub_dr
  provider = aws.hub-dr
}

data "aws_subnet" "subnet_gw_main" {
  id       = var.subnet_gw_main
  provider = aws.gw-main
}

data "aws_subnet" "subnet_gw_dr" {
  id       = var.subnet_gw_dr
  provider = aws.gw-dr
}

locals {
  hub_main_private_key_file_path = var.hub_main_key_pair != null ? var.hub_main_key_pair.private_key_file_path : module.key_pair_hub_main[0].private_key_file_path
  hub_main_public_key_name       = var.hub_main_key_pair != null ? var.hub_main_key_pair.public_key_name : module.key_pair_hub_main[0].key_pair.key_pair_name
  hub_dr_private_key_file_path   = var.hub_dr_key_pair != null ? var.hub_dr_key_pair.private_key_file_path : module.key_pair_hub_dr[0].private_key_file_path
  hub_dr_public_key_name         = var.hub_dr_key_pair != null ? var.hub_dr_key_pair.public_key_name : module.key_pair_hub_dr[0].key_pair.key_pair_name
  gw_main_private_key_file_path  = var.gw_main_key_pair != null ? var.gw_main_key_pair.private_key_file_path : module.key_pair_gw_main[0].private_key_file_path
  gw_main_public_key_name        = var.gw_main_key_pair != null ? var.gw_main_key_pair.public_key_name : module.key_pair_gw_main[0].key_pair.key_pair_name
  gw_dr_private_key_file_path    = var.gw_dr_key_pair != null ? var.gw_dr_key_pair.private_key_file_path : module.key_pair_gw_dr[0].private_key_file_path
  gw_dr_public_key_name          = var.gw_dr_key_pair != null ? var.gw_dr_key_pair.public_key_name : module.key_pair_gw_dr[0].key_pair.key_pair_name
}

##############################
# Generating deployment
##############################
module "hub_main" {
  source               = "imperva/dsf-hub/aws"
  version              = "1.5.6" # latest release tag
  friendly_name        = join("-", [local.deployment_name_salted, "hub", "main"])
  subnet_id            = var.subnet_hub_main
  security_group_ids   = var.security_group_ids_hub_main
  binaries_location    = local.tarball_location
  password             = local.password
  password_secret_name = var.password_secret_name
  instance_type        = var.hub_instance_type
  ebs                  = var.hub_ebs_details
  ami                  = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_main_private_key_file_path
    ssh_public_key_name       = local.hub_main_public_key_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.subnet_hub_dr.cidr_block]
  allowed_agentless_gw_cidrs        = [data.aws_subnet.subnet_gw_main.cidr_block, data.aws_subnet.subnet_gw_dr.cidr_block]
  allowed_ssh_cidrs                 = concat(local.workstation_cidr, ["${var.proxy_private_address}/32"])
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_hub_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  base_directory                    = var.sonar_machine_base_directory
  tags                              = local.tags
  send_usage_statistics = var.send_usage_statistics
  providers = {
    aws = aws.hub-main
  }
}

module "hub_dr" {
  source                       = "imperva/dsf-hub/aws"
  version                      = "1.5.6" # latest release tag
  friendly_name                = join("-", [local.deployment_name_salted, "hub", "DR"])
  subnet_id                    = var.subnet_hub_dr
  security_group_ids           = var.security_group_ids_hub_dr
  binaries_location            = local.tarball_location
  password                     = local.password
  password_secret_name         = var.password_secret_name
  instance_type                = var.hub_instance_type
  ebs                          = var.hub_ebs_details
  ami                          = var.ami
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.hub_main.sonarw_public_key
  main_node_sonarw_private_key = module.hub_main.sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_dr_private_key_file_path
    ssh_public_key_name       = local.hub_dr_public_key_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.subnet_hub_main.cidr_block]
  allowed_agentless_gw_cidrs        = [data.aws_subnet.subnet_gw_main.cidr_block, data.aws_subnet.subnet_gw_dr.cidr_block]
  allowed_ssh_cidrs                 = concat(local.workstation_cidr, ["${var.proxy_private_address}/32"])
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_hub_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  base_directory                    = var.sonar_machine_base_directory
  tags                              = local.tags
  send_usage_statistics = var.send_usage_statistics
  providers = {
    aws = aws.hub-dr
  }
}

module "agentless_gw_main" {
  count                 = var.gw_count
  source                = "imperva/dsf-agentless-gw/aws"
  version               = "1.5.6" # latest release tag
  friendly_name         = join("-", [local.deployment_name_salted, "gw", count.index, "main"])
  subnet_id             = var.subnet_gw_main
  security_group_ids    = var.security_group_ids_gw_main
  instance_type         = var.gw_instance_type
  ebs                   = var.agentless_gw_ebs_details
  binaries_location     = local.tarball_location
  password              = local.password
  password_secret_name  = var.password_secret_name
  hub_sonarw_public_key = module.hub_main.sonarw_public_key
  ami                   = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.gw_main_private_key_file_path
    ssh_public_key_name       = local.gw_main_public_key_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.subnet_gw_dr.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.subnet_hub_main.cidr_block, data.aws_subnet.subnet_hub_dr.cidr_block]
  allowed_ssh_cidrs          = concat(local.workstation_cidr, ["${var.proxy_private_address}/32"])
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_gw_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_gw_public_key_file_path)), null)
  instance_profile_name             = var.gw_instance_profile_name
  base_directory                    = var.sonar_machine_base_directory
  tags                              = local.tags
  send_usage_statistics = var.send_usage_statistics
  providers = {
    aws = aws.gw-main
  }
}

module "agentless_gw_dr" {
  count                        = var.gw_count
  source                       = "imperva/dsf-agentless-gw/aws"
  version                      = "1.5.6" # latest release tag
  friendly_name                = join("-", [local.deployment_name_salted, "gw", count.index, "DR"])
  subnet_id                    = var.subnet_gw_dr
  security_group_ids           = var.security_group_ids_gw_dr
  instance_type                = var.gw_instance_type
  ebs                          = var.agentless_gw_ebs_details
  binaries_location            = local.tarball_location
  password                     = local.password
  password_secret_name         = var.password_secret_name
  hub_sonarw_public_key        = module.hub_main.sonarw_public_key
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.agentless_gw_main[count.index].sonarw_public_key
  main_node_sonarw_private_key = module.agentless_gw_main[count.index].sonarw_private_key
  ami                          = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.gw_dr_private_key_file_path
    ssh_public_key_name       = local.gw_dr_public_key_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.subnet_gw_main.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.subnet_hub_main.cidr_block, data.aws_subnet.subnet_hub_dr.cidr_block]
  allowed_ssh_cidrs          = concat(local.workstation_cidr, ["${var.proxy_private_address}/32"])
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_gw_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_gw_public_key_file_path)), null)
  instance_profile_name             = var.gw_instance_profile_name
  base_directory                    = var.sonar_machine_base_directory
  tags                              = local.tags
  send_usage_statistics = var.send_usage_statistics
  providers = {
    aws = aws.gw-dr
  }
}

module "hub_hadr" {
  source              = "imperva/dsf-hadr/null"
  version             = "1.5.6" # latest release tag
  sonar_version       = module.globals.tarball_location.version
  dsf_main_ip         = module.hub_main.private_ip
  dsf_main_private_ip = module.hub_main.private_ip
  dsf_dr_ip           = module.hub_dr.private_ip
  dsf_dr_private_ip   = module.hub_dr.private_ip
  ssh_key_path        = local.hub_main_private_key_file_path
  ssh_key_path_dr     = local.hub_dr_private_key_file_path
  ssh_user            = module.hub_main.ssh_user
  ssh_user_dr         = module.hub_dr.ssh_user
  proxy_info = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  depends_on = [
    module.hub_main,
    module.hub_dr
  ]
}

module "agentless_gw_hadr" {
  count               = var.gw_count
  source              = "imperva/dsf-hadr/null"
  version             = "1.5.6" # latest release tag
  sonar_version       = module.globals.tarball_location.version
  dsf_main_ip         = module.agentless_gw_main[count.index].private_ip
  dsf_main_private_ip = module.agentless_gw_main[count.index].private_ip
  dsf_dr_ip           = module.agentless_gw_dr[count.index].private_ip
  dsf_dr_private_ip   = module.agentless_gw_dr[count.index].private_ip
  ssh_key_path        = local.gw_main_private_key_file_path
  ssh_key_path_dr     = local.gw_dr_private_key_file_path
  ssh_user            = module.agentless_gw_main[count.index].ssh_user
  ssh_user_dr         = module.agentless_gw_dr[count.index].ssh_user
  proxy_info = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  depends_on = [
    module.agentless_gw_main,
    module.agentless_gw_dr
  ]
}

locals {
  hub_gws_combinations = setproduct(
    [{ instance : module.hub_main, private_key_file_path : local.hub_main_private_key_file_path }, { instance : module.hub_dr, private_key_file_path : local.hub_dr_private_key_file_path }],
    concat(
      [for idx, val in module.agentless_gw_main : { instance : val, private_key_file_path : local.gw_main_private_key_file_path }],
      [for idx, val in module.agentless_gw_dr : { instance : val, private_key_file_path : local.gw_dr_private_key_file_path }]
    )
  )
}

module "federation" {
  count   = length(local.hub_gws_combinations)
  source  = "imperva/dsf-federation/null"
  version = "1.5.6" # latest release tag
  gw_info = {
    gw_ip_address           = local.hub_gws_combinations[count.index][1].instance.private_ip
    gw_private_ssh_key_path = local.hub_gws_combinations[count.index][1].private_key_file_path
    gw_ssh_user             = local.hub_gws_combinations[count.index][1].instance.ssh_user
  }
  hub_info = {
    hub_ip_address           = local.hub_gws_combinations[count.index][0].instance.private_ip
    hub_private_ssh_key_path = local.hub_gws_combinations[count.index][0].private_key_file_path
    hub_ssh_user             = local.hub_gws_combinations[count.index][0].instance.ssh_user
  }
  hub_proxy_info = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  gw_proxy_info = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_hadr
  ]
}
