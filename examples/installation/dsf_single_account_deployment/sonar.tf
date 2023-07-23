locals {
  tarball_location   = var.tarball_location != null ? var.tarball_location : module.globals.tarball_location
  agentless_gw_count = var.enable_sonar ? var.agentless_gw_count : 0

  hub_primary_public_ip   = length(module.hub_primary[0].public_ip) > 0 ? format("%s/32", module.hub_primary[0].public_ip) : null
  hub_secondary_public_ip = length(module.hub_secondary[0].public_ip) > 0 ? format("%s/32", module.hub_secondary[0].public_ip) : null
  hub_cidr_list           = compact([data.aws_subnet.hub_primary.cidr_block, data.aws_subnet.hub_secondary.cidr_block, local.hub_primary_public_ip, local.hub_secondary_public_ip])
  agentless_gw_cidr_list  = [data.aws_subnet.agentless_gw_primary.cidr_block, data.aws_subnet.agentless_gw_secondary.cidr_block]
  hub_primary_ip = length(module.hub_primary[0].public_dns) > 0 ? module.hub_primary[0].public_dns : module.hub_primary[0].private_dns
  hub_secondary_ip = length(module.hub_secondary[0].public_dns) > 0 ? module.hub_secondary[0].public_dns : module.hub_secondary[0].private_dns
}

module "hub_primary" {
  source  = "imperva/dsf-hub/aws"
  version = "1.5.1" # latest release tag
  count   = var.enable_sonar ? 1 : 0

  friendly_name        = join("-", [local.deployment_name_salted, "hub", "primary"])
  instance_type        = var.hub_instance_type
  subnet_id            = var.subnet_ids.hub_primary_subnet_id
  security_group_ids   = var.security_group_ids_hub_primary
  ebs                  = var.hub_ebs_details
  ami                  = var.sonar_ami
  binaries_location    = local.tarball_location
  password             = local.password
  password_secret_name = var.password_secret_name
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_primary_private_key_file_path
    ssh_public_key_name       = local.hub_primary_public_key_name
  }
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.hub_secondary.cidr_block]
  allowed_agentless_gw_cidrs        = local.agentless_gw_cidr_list
  allowed_dra_admin_cidrs           = local.dra_admin_cidr_list
  allowed_all_cidrs                 = var.proxy_private_address != null ? concat(local.workstation_cidr, ["${var.proxy_private_address}/32"]) : local.workstation_cidr
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.sonar_terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_hub_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  mx_details = var.enable_dam ? [for mx in module.mx : {
    name     = mx.display_name
    address  = coalesce(mx.public_dns, mx.private_dns)
    username = mx.web_console_user
    password = local.password
  }] : []
  generate_access_tokens = true
  tags                   = local.tags
  providers = {
    aws = aws.provider-1
  }
}

module "hub_secondary" {
  source  = "imperva/dsf-hub/aws"
  version = "1.5.1" # latest release tag
  count   = var.enable_sonar && var.hub_hadr ? 1 : 0

  friendly_name                   = join("-", [local.deployment_name_salted, "hub", "secondary"])
  instance_type                   = var.hub_instance_type
  subnet_id                       = var.subnet_ids.hub_secondary_subnet_id
  security_group_ids              = var.security_group_ids_hub_secondary
  ebs                             = var.hub_ebs_details
  ami                             = var.sonar_ami
  binaries_location               = local.tarball_location
  password                        = local.password
  password_secret_name            = var.password_secret_name
  hadr_secondary_node             = true
  primary_node_sonarw_public_key  = module.hub_primary[0].sonarw_public_key
  primary_node_sonarw_private_key = module.hub_primary[0].sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_secondary_private_key_file_path
    ssh_public_key_name       = local.hub_secondary_public_key_name
  }
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.hub_primary.cidr_block]
  allowed_agentless_gw_cidrs        = local.agentless_gw_cidr_list
  allowed_dra_admin_cidrs           = local.dra_admin_cidr_list
  allowed_all_cidrs                 = var.proxy_private_address != null ? concat(local.workstation_cidr, ["${var.proxy_private_address}/32"]) : local.workstation_cidr
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.sonar_terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_hub_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  generate_access_tokens            = true
  tags                              = local.tags
  providers = {
    aws = aws.provider-1
  }
}

module "hub_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.5.1" # latest release tag
  count   = length(module.hub_secondary) > 0 ? 1 : 0

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.hub_primary[0].private_ip
  dsf_primary_private_ip   = module.hub_primary[0].private_ip
  dsf_secondary_ip         = module.hub_secondary[0].private_ip
  dsf_secondary_private_ip = module.hub_secondary[0].private_ip
  ssh_key_path             = local.hub_primary_private_key_file_path
  ssh_key_path_secondary   = local.hub_secondary_private_key_file_path
  ssh_user                 = module.hub_primary[0].ssh_user
  ssh_user_secondary       = module.hub_secondary[0].ssh_user
  proxy_info = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  depends_on = [
    module.hub_primary,
    module.hub_secondary
  ]
}

module "agentless_gw_primary" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.5.1" # latest release tag
  count   = local.agentless_gw_count

  friendly_name        = join("-", [local.deployment_name_salted, "agentless", "gw", "primary", count.index])
  instance_type        = var.agentless_gw_instance_type
  subnet_id            = var.subnet_ids.agentless_gw_primary_subnet_id
  security_group_ids   = var.security_group_ids_gw_primary
  ebs                  = var.agentless_gw_ebs_details
  ami                  = var.sonar_ami
  binaries_location    = local.tarball_location
  password             = local.password
  password_secret_name = var.password_secret_name
  ssh_key_pair = {
    ssh_private_key_file_path = local.agentless_gw_primary_private_key_file_path
    ssh_public_key_name       = local.agentless_gw_primary_public_key_name
  }
  hub_sonarw_public_key = module.hub_primary[0].sonarw_public_key
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  allowed_agentless_gw_cidrs        = [data.aws_subnet.agentless_gw_secondary.cidr_block]
  allowed_hub_cidrs                 = [data.aws_subnet.hub_primary.cidr_block, data.aws_subnet.hub_secondary.cidr_block]
  allowed_all_cidrs                 = var.proxy_private_address != null ? concat(local.workstation_cidr, ["${var.proxy_private_address}/32"]) : local.workstation_cidr
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.sonar_terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_gw_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_gw_public_key_file_path)), null)
  instance_profile_name             = var.agentless_gw_instance_profile_name
  tags                              = local.tags
  providers = {
    aws = aws.provider-2
  }
}

module "agentless_gw_secondary" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.5.1" # latest release tag
  count   = var.agentless_gw_hadr ? local.agentless_gw_count : 0

  friendly_name                   = join("-", [local.deployment_name_salted, "agentless", "gw", "secondary", count.index])
  instance_type                   = var.agentless_gw_instance_type
  subnet_id                       = var.subnet_ids.agentless_gw_secondary_subnet_id
  security_group_ids              = var.security_group_ids_gw_secondary
  ebs                             = var.agentless_gw_ebs_details
  ami                             = var.sonar_ami
  binaries_location               = local.tarball_location
  password                        = local.password
  password_secret_name            = var.password_secret_name
  hadr_secondary_node             = true
  primary_node_sonarw_public_key  = module.agentless_gw_primary[count.index].sonarw_public_key
  primary_node_sonarw_private_key = module.agentless_gw_primary[count.index].sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = local.agentless_gw_secondary_private_key_file_path
    ssh_public_key_name       = local.agentless_gw_secondary_public_key_name
  }
  hub_sonarw_public_key = module.hub_primary[0].sonarw_public_key
  ingress_communication_via_proxy = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  allowed_agentless_gw_cidrs        = [data.aws_subnet.agentless_gw_primary.cidr_block]
  allowed_hub_cidrs                 = [data.aws_subnet.hub_primary.cidr_block, data.aws_subnet.hub_secondary.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr
  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.sonar_terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_gw_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_gw_public_key_file_path)), null)
  instance_profile_name             = var.agentless_gw_instance_profile_name
  tags                              = local.tags
  providers = {
    aws = aws.provider-2
  }
}

module "agentless_gw_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.5.1" # latest release tag
  count   = length(module.agentless_gw_secondary)

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.agentless_gw_primary[count.index].private_ip
  dsf_primary_private_ip   = module.agentless_gw_primary[count.index].private_ip
  dsf_secondary_ip         = module.agentless_gw_secondary[count.index].private_ip
  dsf_secondary_private_ip = module.agentless_gw_secondary[count.index].private_ip
  ssh_key_path             = local.agentless_gw_primary_private_key_file_path
  ssh_key_path_secondary   = local.agentless_gw_secondary_private_key_file_path
  ssh_user                 = module.agentless_gw_primary[count.index].ssh_user
  ssh_user_secondary       = module.agentless_gw_secondary[count.index].ssh_user
  proxy_info = var.proxy_address != null ? {
    proxy_address              = var.proxy_address
    proxy_private_ssh_key_path = var.proxy_ssh_key_path
    proxy_ssh_user             = var.proxy_ssh_user
  } : null
  depends_on = [
    module.agentless_gw_primary,
    module.agentless_gw_secondary
  ]
}

locals {
  gws = merge(
    { for idx, val in module.agentless_gw_primary : "agentless-gw-${idx}" => { instance : val, private_key_file_path : local.agentless_gw_primary_private_key_file_path } },
    { for idx, val in module.agentless_gw_secondary : "agentless-gw-secondary-${idx}" => { instance : val, private_key_file_path : local.agentless_gw_secondary_private_key_file_path } },
  )
  gws_set = values(local.gws)
  hubs_set = concat(
    var.enable_sonar ? [{ instance : module.hub_primary[0], ip : hub_primary_ip, private_key_file_path : local.hub_primary_private_key_file_path }] : [],
    var.enable_sonar && var.hub_hadr ? [{ instance : module.hub_secondary[0], ip : hub_secondary_ip, private_key_file_path : local.hub_secondary_private_key_file_path }] : []
  )
  hubs_keys = compact([
    var.enable_sonar ? "hub-primary" : null,
    var.enable_sonar && var.hub_hadr ? "hub-secondary" : null,
  ])

  hub_gw_combinations_values = setproduct(local.hubs_set, local.gws_set)
  hub_gw_combinations_keys   = [for v in setproduct(local.hubs_keys, keys(local.gws)) : "${v[0]}-${v[1]}"]

  hub_gw_combinations = zipmap(local.hub_gw_combinations_keys, local.hub_gw_combinations_values)
}

module "federation" {
  source   = "imperva/dsf-federation/null"
  version  = "1.5.1" # latest release tag
  for_each = local.hub_gw_combinations

  hub_info = {
    hub_ip_address           = each.value[0].ip
    hub_private_ssh_key_path = each.value[0].private_key_file_path
    hub_ssh_user             = each.value[0].instance.ssh_user
  }
  gw_info = {
    gw_ip_address           = each.value[1].instance.private_ip
    gw_private_ssh_key_path = each.value[1].private_key_file_path
    gw_ssh_user             = each.value[1].instance.ssh_user
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
