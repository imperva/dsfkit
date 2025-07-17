locals {
  agentless_gw_count = var.enable_sonar ? var.agentless_gw_count : 0

  hub_public_ip    = var.enable_sonar ? (length(module.hub_main[0].public_ip) > 0 ? format("%s/32", module.hub_main[0].public_ip) : null) : null
  hub_dr_public_ip = var.enable_sonar && var.hub_hadr ? (length(module.hub_dr[0].public_ip) > 0 ? format("%s/32", module.hub_dr[0].public_ip) : null) : null
  #  WA since the following doesn't work: hub_cidr_list = concat(local.subnet_address_spaces, compact([local.hub_public_ip, local.hub_dr_public_ip]))
  hub_cidr_list = var.enable_sonar ? (var.hub_hadr ? concat(local.subnet_address_spaces, [local.hub_public_ip, local.hub_dr_public_ip]) : concat(local.subnet_address_spaces, [local.hub_public_ip])) : local.subnet_address_spaces
}

module "hub_main" {
  source  = "imperva/dsf-hub/azurerm"
  version = "1.7.31" # latest release tag
  count   = var.enable_sonar ? 1 : 0

  friendly_name               = join("-", [local.deployment_name_salted, "hub"])
  resource_group              = local.resource_group
  subnet_id                   = local.hub_subnet_id
  binaries_location           = var.tarball_location
  tarball_url                 = var.tarball_url
  password                    = local.password
  storage_details             = var.hub_storage_details
  instance_size               = var.hub_instance_size
  base_directory              = var.sonar_machine_base_directory
  attach_persistent_public_ip = true
  use_public_ip               = true
  generate_access_tokens      = true
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = local.subnet_address_spaces
  allowed_agentless_gw_cidrs        = local.subnet_address_spaces
  allowed_dra_admin_cidrs           = local.dra_admin_cidr_list
  allowed_all_cidrs                 = local.workstation_cidr
  allowed_ssh_cidrs                 = var.allowed_ssh_cidrs
  mx_details = var.enable_dam ? [for mx in module.mx : {
    name     = mx.display_name
    address  = coalesce(mx.public_ip, mx.private_ip)
    username = mx.web_console_user
    password = local.password
  }] : []
  dra_details = var.enable_dra ? {
    name              = module.dra_admin[0].display_name
    address           = module.dra_admin[0].public_ip
    password          = local.password
    archiver_username = module.dra_analytics[0].archiver_user
    archiver_password = module.dra_analytics[0].archiver_password
  } : null
  tags = local.tags

  depends_on = [
    module.network
  ]
}

module "hub_dr" {
  source  = "imperva/dsf-hub/azurerm"
  version = "1.7.31" # latest release tag
  count   = var.enable_sonar && var.hub_hadr ? 1 : 0

  friendly_name                = join("-", [local.deployment_name_salted, "hub", "DR"])
  resource_group               = local.resource_group
  subnet_id                    = local.hub_dr_subnet_id
  binaries_location            = var.tarball_location
  tarball_url                  = var.tarball_url
  password                     = local.password
  storage_details              = var.hub_storage_details
  instance_size                = var.hub_instance_size
  base_directory               = var.sonar_machine_base_directory
  attach_persistent_public_ip  = true
  use_public_ip                = true
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.hub_main[0].sonarw_public_key
  main_node_sonarw_private_key = module.hub_main[0].sonarw_private_key
  generate_access_tokens       = true
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = local.subnet_address_spaces
  allowed_agentless_gw_cidrs        = local.subnet_address_spaces
  allowed_dra_admin_cidrs           = local.dra_admin_cidr_list
  allowed_all_cidrs                 = local.workstation_cidr
  allowed_ssh_cidrs                 = var.allowed_ssh_cidrs
  tags                              = local.tags
  depends_on = [
    module.network
  ]
}

module "hub_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.7.31" # latest release tag
  count   = length(module.hub_dr) > 0 ? 1 : 0

  sonar_version       = var.sonar_version
  dsf_main_ip         = module.hub_main[0].public_ip
  dsf_main_private_ip = module.hub_main[0].private_ip
  dsf_dr_ip           = module.hub_dr[0].public_ip
  dsf_dr_private_ip   = module.hub_dr[0].private_ip
  ssh_key_path        = local_sensitive_file.ssh_key.filename
  ssh_user            = module.hub_main[0].ssh_user
  depends_on = [
    module.hub_main,
    module.hub_dr
  ]
}

module "agentless_gw_main" {
  source  = "imperva/dsf-agentless-gw/azurerm"
  version = "1.7.31" # latest release tag
  count   = local.agentless_gw_count

  friendly_name         = join("-", [local.deployment_name_salted, "agentless", "gw", count.index])
  resource_group        = local.resource_group
  subnet_id             = local.agentless_gw_subnet_id
  storage_details       = var.agentless_gw_storage_details
  binaries_location     = var.tarball_location
  tarball_url           = var.tarball_url
  instance_size         = var.agentless_gw_instance_size
  base_directory        = var.sonar_machine_base_directory
  password              = local.password
  hub_sonarw_public_key = module.hub_main[0].sonarw_public_key
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_agentless_gw_cidrs = local.subnet_address_spaces
  allowed_hub_cidrs          = local.subnet_address_spaces
  allowed_all_cidrs          = local.workstation_cidr
  allowed_ssh_cidrs          = var.allowed_ssh_cidrs
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.network
  ]
}

module "agentless_gw_dr" {
  source  = "imperva/dsf-agentless-gw/azurerm"
  version = "1.7.31" # latest release tag
  count   = var.agentless_gw_hadr ? local.agentless_gw_count : 0

  friendly_name                = join("-", [local.deployment_name_salted, "agentless", "gw", count.index, "DR"])
  resource_group               = local.resource_group
  subnet_id                    = local.agentless_gw_dr_subnet_id
  storage_details              = var.agentless_gw_storage_details
  binaries_location            = var.tarball_location
  tarball_url                  = var.tarball_url
  instance_size                = var.agentless_gw_instance_size
  base_directory               = var.sonar_machine_base_directory
  password                     = local.password
  hub_sonarw_public_key        = module.hub_main[0].sonarw_public_key
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.agentless_gw_main[count.index].sonarw_public_key
  main_node_sonarw_private_key = module.agentless_gw_main[count.index].sonarw_private_key
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_agentless_gw_cidrs = local.subnet_address_spaces
  allowed_hub_cidrs          = local.subnet_address_spaces
  allowed_all_cidrs          = local.workstation_cidr
  allowed_ssh_cidrs          = var.allowed_ssh_cidrs
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.network
  ]
}

module "agentless_gw_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.7.31" # latest release tag
  count   = length(module.agentless_gw_dr)

  sonar_version       = var.sonar_version
  dsf_main_ip         = module.agentless_gw_main[count.index].private_ip
  dsf_main_private_ip = module.agentless_gw_main[count.index].private_ip
  dsf_dr_ip           = module.agentless_gw_dr[count.index].private_ip
  dsf_dr_private_ip   = module.agentless_gw_dr[count.index].private_ip
  ssh_key_path        = local_sensitive_file.ssh_key.filename
  ssh_user            = module.agentless_gw_main[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  depends_on = [
    module.agentless_gw_main,
    module.agentless_gw_dr,
  ]
}

module "gw_main_federation" {
  source  = "imperva/dsf-federation/null"
  version = "1.7.31" # latest release tag

  for_each = {
    for idx, val in module.agentless_gw_main : idx => val
  }

  hub_info = {
    hub_ip_address            = module.hub_main[0].public_ip
    hub_federation_ip_address = module.hub_main[0].public_ip
    hub_private_ssh_key_path  = local_sensitive_file.ssh_key.filename
    hub_ssh_user              = module.hub_main[0].ssh_user
  }
  gw_info = {
    gw_ip_address            = each.value.private_ip
    gw_federation_ip_address = each.value.private_ip
    gw_private_ssh_key_path  = local_sensitive_file.ssh_key.filename
    gw_ssh_user              = each.value.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  depends_on = [
    module.hub_main,
    module.agentless_gw_main,

    module.hub_hadr,
    module.agentless_gw_hadr
  ]
}

resource "null_resource" "force_gw_replication" {
  # for_each = module.agentless_gw_dr
  for_each = { for idx, val in module.agentless_gw_dr : idx => val }

  provisioner "local-exec" {
    command     = <<-EOT
    #!/bin/bash
    set -x -e

    PROXY_CMD='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local_sensitive_file.ssh_key.filename} -W %h:%p ${module.hub_main[0].ssh_user}@${module.hub_main[0].public_ip}'

    # wait for existing replication to finish
    while [[ "$(ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="$PROXY_CMD" -i ${local_sensitive_file.ssh_key.filename} ${each.value.ssh_user}@${each.value.private_ip} 'sudo $JSONAR_BASEDIR/bin/arbiter-setup is-repl-running')" != *"No replication cycle is currently running"* ]]; do
        sleep 10
    done

    # force replication to make sure we are up to date
    ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="$PROXY_CMD" -i ${local_sensitive_file.ssh_key.filename} ${each.value.ssh_user}@${each.value.private_ip} 'sudo $JSONAR_BASEDIR/bin/arbiter-setup run-replication'
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [
    module.agentless_gw_dr,

    module.gw_main_federation,
  ]
}

module "gw_dr_federation" {
  source  = "imperva/dsf-federation/null"
  version = "1.7.31" # latest release tag

  for_each = {
    for idx, val in module.agentless_gw_dr : idx => val
  }

  hub_info = {
    hub_ip_address            = module.hub_main[0].public_ip
    hub_federation_ip_address = module.hub_main[0].public_ip
    hub_private_ssh_key_path  = local_sensitive_file.ssh_key.filename
    hub_ssh_user              = module.hub_main[0].ssh_user
  }
  gw_info = {
    gw_ip_address            = each.value.private_ip
    gw_federation_ip_address = each.value.private_ip
    gw_private_ssh_key_path  = local_sensitive_file.ssh_key.filename
    gw_ssh_user              = each.value.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  depends_on = [
    null_resource.force_gw_replication,
  ]
}

module "hub_dr_federation" {
  source  = "imperva/dsf-federation/null"
  version = "1.7.31" # latest release tag

  for_each = var.hub_hadr ? {
    for idx, val in concat(module.agentless_gw_main, module.agentless_gw_dr) : idx => val
  } : {}

  hub_info = {
    hub_ip_address            = module.hub_dr[0].public_ip
    hub_federation_ip_address = module.hub_dr[0].public_ip
    hub_private_ssh_key_path  = local_sensitive_file.ssh_key.filename
    hub_ssh_user              = module.hub_dr[0].ssh_user
  }
  gw_info = {
    gw_ip_address            = each.value.private_ip
    gw_federation_ip_address = each.value.private_ip
    gw_private_ssh_key_path  = local_sensitive_file.ssh_key.filename
    gw_ssh_user              = each.value.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  depends_on = [
    module.hub_dr,
    module.agentless_gw_main,
    module.agentless_gw_dr,

    module.gw_dr_federation
  ]
}


resource "null_resource" "sonar_setup_completed" {
  depends_on = [
    module.hub_main,
    module.hub_dr,
    module.hub_hadr,

    module.agentless_gw_main,
    module.agentless_gw_dr,
    module.agentless_gw_hadr,

    module.gw_main_federation,
    module.hub_dr_federation,
    module.gw_dr_federation,
  ]
}
