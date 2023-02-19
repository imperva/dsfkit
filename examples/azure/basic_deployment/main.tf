provider "azurerm" {
  # tbd: verify how a customer would pass on his creds to this provider https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "globals" {
  # source        = "imperva/dsf-globals/aws"
  # version       = "1.3.5" # latest release tag
  source        = "../../../modules/azurerm/core/globals"
  sonar_version = var.sonar_version
}

locals {
  workstation_cidr_24        = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
  deployment_name_salted     = join("-", [var.deployment_name, module.globals.salt])
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  # database_cidr              = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location = module.globals.tarball_location
  # tbd: add tags to all resources
  tags = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  resource_group = {
    location = azurerm_resource_group.rg.location
    name     = azurerm_resource_group.rg.name
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.deployment_name
  location = var.location
}

# create key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ssh_key" {
  filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
  content  = tls_private_key.ssh_key.private_key_openssh
}

# network
module "network" {
  source              = "Azure/network/azurerm"
  vnet_name           = "${local.deployment_name_salted}-${module.globals.current_user_name}"
  resource_group_name = azurerm_resource_group.rg.name
  address_spaces      = [var.network_ip_range]
  subnet_prefixes     = var.private_subnets
  subnet_names        = formatlist("subnet-%d", range(length(var.private_subnets)))

  use_for_each = true
  tags         = local.tags
  depends_on = [
    azurerm_resource_group.rg
  ]
}

##############################
# Generating deployment
##############################
module "hub" {
  # count  = 0
  source = "../../../modules/azurerm/hub"
  # version                             = "1.3.5" # latest release tag

  friendly_name              = join("-", [local.deployment_name_salted, "hub", "primary"])
  resource_group             = local.resource_group
  subnet_id                  = module.network.vnet_subnets[0]
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  storage_details            = var.hub_managed_disk_details

  # tbd: change the "elastic" terminology
  create_and_attach_public_elastic_ip = true

  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = local.workstation_cidr
    use_public_ip                           = true
  }

  depends_on = [
    azurerm_resource_group.rg,
    module.network
  ]
}

# ##############################
# # Generating deployment
# ##############################

module "agentless_gw_group" {
  count  = var.gw_count
  source = "../../../modules/azurerm/agentless-gw"
  # version                             = "1.3.5" # latest release tag

  friendly_name                       = join("-", [local.deployment_name_salted, "gw", count.index])
  resource_group                      = local.resource_group
  subnet_id                           = module.network.vnet_subnets[0]
  storage_details                     = var.hub_managed_disk_details
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  hub_sonarw_public_key               = module.hub.sonarw_public_key
  create_and_attach_public_elastic_ip = false
  # create_and_attach_public_elastic_ip = true
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub.private_ip}/32"])
    use_public_ip         = false
    # use_public_ip         = true
  }
  ingress_communication_via_proxy = {
    proxy_address              = module.hub.public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.network
  ]
}

module "federation" {
  for_each = { for idx, val in module.agentless_gw_group : idx => val }
  source   = "imperva/dsf-federation/null"
  gw_info = {
    gw_ip_address = each.value.private_ip
    # gw_ip_address           = each.value.public_ip
    gw_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    gw_ssh_user             = each.value.ssh_user
  }
  hub_info = {
    hub_ip_address           = module.hub.public_ip
    hub_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    hub_ssh_user             = module.hub.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub.public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.hub,
    module.agentless_gw_group,
  ]
}

# module "rds_mysql" {
#   count                        = 1
#   source                       = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mysql-db"
#   rds_subnet_ids               = module.vpc.public_subnets
#   security_group_ingress_cidrs = local.workstation_cidr
# }

# module "db_onboarding" {
#   for_each      = { for idx, val in module.rds_mysql : idx => val }
#   source        = "imperva/dsf-poc-db-onboarder/aws"
#   sonar_version = module.globals.tarball_location.version
#   hub_info = {
#     hub_ip_address           = module.hub.public_ip
#     hub_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
#     hub_ssh_user             = module.hub.ssh_user
#   }
#   assignee_gw   = module.hub.jsonar_uid
#   assignee_role = module.hub.iam_role
#   database_details = {
#     db_username   = each.value.db_username
#     db_password   = each.value.db_password
#     db_arn        = each.value.db_arn
#     db_port       = each.value.db_port
#     db_identifier = each.value.db_identifier
#     db_address    = each.value.db_endpoint
#     db_engine     = each.value.db_engine
#   }
#   depends_on = [
#     module.federation,
#     module.rds_mysql
#   ]
# }

# module "statistics" {
#   source = "imperva/dsf-statistics/aws"
# }

# output "db_details" {
#   value = module.rds_mysql
# }
