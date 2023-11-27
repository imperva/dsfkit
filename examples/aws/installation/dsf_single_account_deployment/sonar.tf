locals {
  tarball_location   = var.tarball_location != null ? var.tarball_location : module.globals.tarball_location
  agentless_gw_count = var.enable_sonar ? var.agentless_gw_count : 0

  hub_main_public_ip     = var.enable_sonar ? (length(module.hub_main[0].public_ip) > 0 ? format("%s/32", module.hub_main[0].public_ip) : null) : null
  hub_dr_public_ip       = var.enable_sonar ? (length(module.hub_dr[0].public_ip) > 0 ? format("%s/32", module.hub_dr[0].public_ip) : null) : null
  hub_cidr_list          = compact([data.aws_subnet.hub_main.cidr_block, data.aws_subnet.hub_dr.cidr_block, local.hub_main_public_ip, local.hub_dr_public_ip])
  agentless_gw_cidr_list = [data.aws_subnet.agentless_gw_main.cidr_block, data.aws_subnet.agentless_gw_dr.cidr_block]
  hub_main_ip            = var.enable_sonar ? (length(module.hub_main[0].public_dns) > 0 ? module.hub_main[0].public_dns : module.hub_main[0].private_dns) : null
  hub_dr_ip              = var.enable_sonar ? (length(module.hub_dr[0].public_dns) > 0 ? module.hub_dr[0].public_dns : module.hub_dr[0].private_dns) : null
}

module "hub_main" {
  source  = "imperva/dsf-hub/aws"
  version = "1.7.1" # latest release tag
  count   = var.enable_sonar ? 1 : 0

  friendly_name        = join("-", [local.deployment_name_salted, "hub", "main"])
  instance_type        = var.hub_instance_type
  subnet_id            = var.subnet_ids.hub_main_subnet_id
  security_group_ids   = var.security_group_ids_hub_main
  ebs                  = var.hub_ebs_details
  ami                  = var.sonar_ami
  binaries_location    = local.tarball_location
  password             = local.password
  password_secret_name = var.password_secret_name
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_main_private_key_file_path
    ssh_public_key_name       = local.hub_main_public_key_name
  }
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.hub_dr.cidr_block]
  allowed_agentless_gw_cidrs        = local.agentless_gw_cidr_list
  allowed_dra_admin_cidrs           = local.dra_admin_cidr_list
  allowed_all_cidrs                 = var.proxy_private_address != null ? ["${var.proxy_private_address}/32"] : local.workstation_cidr
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.sonar_terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_hub_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  base_directory                    = var.sonar_machine_base_directory
  mx_details = var.enable_dam ? [for mx in module.mx : {
    name     = mx.display_name
    address  = coalesce(mx.public_dns, mx.private_dns)
    username = mx.web_console_user
    password = local.password
  }] : []
  dra_details = var.enable_dra ? {
    name              = module.dra_admin[0].display_name
    address           = module.dra_admin[0].public_ip
    username          = module.dra_admin[0].ssh_user
    password          = local.password
    archiver_password = module.dra_analytics[0].archiver_password
  } : null
  generate_access_tokens = true
  tags                   = local.tags
  send_usage_statistics  = var.send_usage_statistics
  providers = {
    aws = aws.provider-1
  }
}

module "hub_dr" {
  source  = "imperva/dsf-hub/aws"
  version = "1.7.1" # latest release tag
  count   = var.enable_sonar && var.hub_hadr ? 1 : 0

  friendly_name                = join("-", [local.deployment_name_salted, "hub", "DR"])
  instance_type                = var.hub_instance_type
  subnet_id                    = var.subnet_ids.hub_dr_subnet_id
  security_group_ids           = var.security_group_ids_hub_dr
  ebs                          = var.hub_ebs_details
  ami                          = var.sonar_ami
  binaries_location            = local.tarball_location
  password                     = local.password
  password_secret_name         = var.password_secret_name
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.hub_main[0].sonarw_public_key
  main_node_sonarw_private_key = module.hub_main[0].sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_dr_private_key_file_path
    ssh_public_key_name       = local.hub_dr_public_key_name
  }
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.hub_main.cidr_block]
  allowed_agentless_gw_cidrs        = local.agentless_gw_cidr_list
  allowed_dra_admin_cidrs           = local.dra_admin_cidr_list
  allowed_all_cidrs                 = var.proxy_private_address != null ? ["${var.proxy_private_address}/32"] : local.workstation_cidr
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.sonar_terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_hub_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  base_directory                    = var.sonar_machine_base_directory
  generate_access_tokens            = true
  tags                              = local.tags
  send_usage_statistics             = var.send_usage_statistics
  providers = {
    aws = aws.provider-1
  }
}

module "hub_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.7.1" # latest release tag
  count   = length(module.hub_dr) > 0 ? 1 : 0

  sonar_version       = module.globals.tarball_location.version
  dsf_main_ip         = module.hub_main[0].private_ip
  dsf_main_private_ip = module.hub_main[0].private_ip
  dsf_dr_ip           = module.hub_dr[0].private_ip
  dsf_dr_private_ip   = module.hub_dr[0].private_ip
  ssh_key_path        = local.hub_main_private_key_file_path
  ssh_key_path_dr     = local.hub_dr_private_key_file_path
  ssh_user            = module.hub_main[0].ssh_user
  ssh_user_dr         = module.hub_dr[0].ssh_user
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

module "agentless_gw_main" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.7.1" # latest release tag
  count   = local.agentless_gw_count

  friendly_name        = join("-", [local.deployment_name_salted, "agentless", "gw", count.index, "main"])
  instance_type        = var.agentless_gw_instance_type
  subnet_id            = var.subnet_ids.agentless_gw_main_subnet_id
  security_group_ids   = var.security_group_ids_gw_main
  ebs                  = var.agentless_gw_ebs_details
  ami                  = var.sonar_ami
  binaries_location    = local.tarball_location
  password             = local.password
  password_secret_name = var.password_secret_name
  ssh_key_pair = {
    ssh_private_key_file_path = local.agentless_gw_main_private_key_file_path
    ssh_public_key_name       = local.agentless_gw_main_public_key_name
  }
  hub_sonarw_public_key = module.hub_main[0].sonarw_public_key
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  allowed_agentless_gw_cidrs        = [data.aws_subnet.agentless_gw_dr.cidr_block]
  allowed_hub_cidrs                 = [data.aws_subnet.hub_main.cidr_block, data.aws_subnet.hub_dr.cidr_block]
  allowed_all_cidrs                 = var.proxy_private_address != null ? ["${var.proxy_private_address}/32"] : local.workstation_cidr
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.sonar_terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_gw_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_gw_public_key_file_path)), null)
  instance_profile_name             = var.agentless_gw_instance_profile_name
  base_directory                    = var.sonar_machine_base_directory
  tags                              = local.tags
  send_usage_statistics             = var.send_usage_statistics
  providers = {
    aws = aws.provider-2
  }
}

module "agentless_gw_dr" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.7.1" # latest release tag
  count   = var.agentless_gw_hadr ? local.agentless_gw_count : 0

  friendly_name                = join("-", [local.deployment_name_salted, "agentless", "gw", count.index, "DR"])
  instance_type                = var.agentless_gw_instance_type
  subnet_id                    = var.subnet_ids.agentless_gw_dr_subnet_id
  security_group_ids           = var.security_group_ids_gw_dr
  ebs                          = var.agentless_gw_ebs_details
  ami                          = var.sonar_ami
  binaries_location            = local.tarball_location
  password                     = local.password
  password_secret_name         = var.password_secret_name
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.agentless_gw_main[count.index].sonarw_public_key
  main_node_sonarw_private_key = module.agentless_gw_main[count.index].sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = local.agentless_gw_dr_private_key_file_path
    ssh_public_key_name       = local.agentless_gw_dr_public_key_name
  }
  hub_sonarw_public_key = module.hub_main[0].sonarw_public_key
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  allowed_agentless_gw_cidrs        = [data.aws_subnet.agentless_gw_main.cidr_block]
  allowed_hub_cidrs                 = [data.aws_subnet.hub_main.cidr_block, data.aws_subnet.hub_dr.cidr_block]
  allowed_all_cidrs                 = var.proxy_private_address != null ? ["${var.proxy_private_address}/32"] : local.workstation_cidr
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.sonar_terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_gw_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_gw_public_key_file_path)), null)
  instance_profile_name             = var.agentless_gw_instance_profile_name
  base_directory                    = var.sonar_machine_base_directory
  tags                              = local.tags
  send_usage_statistics             = var.send_usage_statistics
  providers = {
    aws = aws.provider-2
  }
}

module "agentless_gw_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.7.1" # latest release tag
  count   = length(module.agentless_gw_dr)

  sonar_version       = module.globals.tarball_location.version
  dsf_main_ip         = module.agentless_gw_main[count.index].private_ip
  dsf_main_private_ip = module.agentless_gw_main[count.index].private_ip
  dsf_dr_ip           = module.agentless_gw_dr[count.index].private_ip
  dsf_dr_private_ip   = module.agentless_gw_dr[count.index].private_ip
  ssh_key_path        = local.agentless_gw_main_private_key_file_path
  ssh_key_path_dr     = local.agentless_gw_dr_private_key_file_path
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
  gws = merge(
    { for idx, val in module.agentless_gw_main : "agentless-gw-${idx}" => { instance : val, private_key_file_path : local.agentless_gw_main_private_key_file_path } },
    { for idx, val in module.agentless_gw_dr : "agentless-gw-dr-${idx}" => { instance : val, private_key_file_path : local.agentless_gw_dr_private_key_file_path } },
  )
  gws_set = values(local.gws)
  hubs_set = concat(
    var.enable_sonar ? [{ instance : module.hub_main[0], ip : local.hub_main_ip, private_key_file_path : local.hub_main_private_key_file_path }] : [],
    var.enable_sonar && var.hub_hadr ? [{ instance : module.hub_dr[0], ip : local.hub_dr_ip, private_key_file_path : local.hub_dr_private_key_file_path }] : []
  )
  hubs_keys = compact([
    var.enable_sonar ? "hub-main" : null,
    var.enable_sonar && var.hub_hadr ? "hub-dr" : null,
  ])

  hub_gw_combinations_values = setproduct(local.hubs_set, local.gws_set)
  hub_gw_combinations_keys   = [for v in setproduct(local.hubs_keys, keys(local.gws)) : "${v[0]}-${v[1]}"]

  hub_gw_combinations = zipmap(local.hub_gw_combinations_keys, local.hub_gw_combinations_values)
}

module "federation" {
  source   = "imperva/dsf-federation/null"
  version  = "1.7.1" # latest release tag
  for_each = local.hub_gw_combinations

  hub_info = {
    hub_ip_address            = each.value[0].ip
    hub_federation_ip_address = each.value[0].ip
    hub_private_ssh_key_path  = each.value[0].private_key_file_path
    hub_ssh_user              = each.value[0].instance.ssh_user
  }
  gw_info = {
    gw_ip_address            = each.value[1].instance.private_ip
    gw_federation_ip_address = each.value[1].instance.private_ip
    gw_private_ssh_key_path  = each.value[1].private_key_file_path
    gw_ssh_user              = each.value[1].instance.ssh_user
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
