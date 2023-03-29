provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source = "../../../modules/aws/core/globals"
  # source        = "imperva/dsf-globals/aws"
  # version       = "1.3.10" # latest release tag
}

module "key_pair" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.10" # latest release tag
  key_name_prefix          = "imperva-dsf-"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  workstation_cidr_24 = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = ["82.166.106.0/24", "94.188.165.0/24"] #var.workstation_cidr # != null ? var.workstation_cidr : local.workstation_cidr_24
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  hub_subnet                 = var.subnet_ids != null ? var.subnet_ids.hub_subnet_id : module.vpc[0].public_subnets[0]
  gw_subnet                  = var.subnet_ids != null ? var.subnet_ids.gw_subnet_id : module.vpc[0].public_subnets[0]
}

##############################
# Generating network
##############################

module "vpc" {
  count  = var.subnet_ids == null ? 1 : 0
  source = "terraform-aws-modules/vpc/aws"
  name   = "${local.deployment_name_salted}-${module.globals.current_user_name}"
  cidr   = var.vpc_ip_range

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

##############################
# Generating deployment
##############################
module "mx" {
  source           = "../../../modules/aws/mx"
  friendly_name    = join("-", [local.deployment_name_salted, "dam"])
  subnet_id        = local.hub_subnet
  license_file     = "license.mprv"
  key_pair         = module.key_pair.key_pair.key_pair_name
  secure_password  = local.web_console_admin_password
  imperva_password = local.web_console_admin_password
  sg_ingress_cidr  = local.workstation_cidr
  sg_ssh_cidr      = local.workstation_cidr
  web_console_cidr = local.workstation_cidr
  attach_public_ip = true
}

module "gw" {
  count                  = 1
  source                 = "../../../modules/aws/gw"
  friendly_name          = join("-", [local.deployment_name_salted, "dam"])
  subnet_id              = local.hub_subnet
  key_pair               = module.key_pair.key_pair.key_pair_name
  secure_password        = local.web_console_admin_password
  imperva_password       = local.web_console_admin_password
  sg_ingress_cidr        = local.workstation_cidr
  sg_ssh_cidr            = local.workstation_cidr
  attach_public_ip       = true
  management_server_host = module.mx.private_ip
}

# module "hub" {
#   source                     = "imperva/dsf-hub/aws"
#   version                    = "1.3.9" # latest release tag
#   friendly_name              = join("-", [local.deployment_name_salted, "hub"])
#   subnet_id                  = local.hub_subnet
#   binaries_location          = local.tarball_location
#   web_console_admin_password = local.web_console_admin_password
#   ebs                        = var.hub_ebs_details
#   attach_public_ip           = true
#   ssh_key_pair = {
#     ssh_private_key_file_path = module.key_pair.private_key_file_path
#     ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
#   }
#   ingress_communication = {
#     additional_web_console_access_cidr_list = var.web_console_cidr
#     full_access_cidr_list                   = concat(local.workstation_cidr, [var.private_subnets[0]])
#   }
#   use_public_ip = true
#   depends_on = [
#     module.vpc
#   ]
# }

# module "agentless_gw_group" {
#   count                      = var.gw_count
#   source                     = "imperva/dsf-agentless-gw/aws"
#   version                    = "1.3.9" # latest release tag
#   friendly_name              = join("-", [local.deployment_name_salted, "gw", count.index])
#   subnet_id                  = local.gw_subnet
#   ebs                        = var.gw_group_ebs_details
#   binaries_location          = local.tarball_location
#   web_console_admin_password = local.web_console_admin_password
#   hub_sonarw_public_key      = module.hub.sonarw_public_key
#   attach_public_ip           = false
#   ssh_key_pair = {
#     ssh_private_key_file_path = module.key_pair.private_key_file_path
#     ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
#   }
#   ingress_communication = {
#     full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub.private_ip}/32"])
#   }
#   use_public_ip = false
#   ingress_communication_via_proxy = {
#     proxy_address              = module.hub.public_ip
#     proxy_private_ssh_key_path = module.key_pair.private_key_file_path
#     proxy_ssh_user             = module.hub.ssh_user
#   }
#   depends_on = [
#     module.vpc,
#   ]
# }

# module "federation" {
#   for_each = { for idx, val in module.agentless_gw_group : idx => val }
#   source   = "imperva/dsf-federation/null"
#   version  = "1.3.9" # latest release tag
#   gw_info = {
#     gw_ip_address           = each.value.private_ip
#     gw_private_ssh_key_path = module.key_pair.private_key_file_path
#     gw_ssh_user             = each.value.ssh_user
#   }
#   hub_info = {
#     hub_ip_address           = module.hub.public_ip
#     hub_private_ssh_key_path = module.key_pair.private_key_file_path
#     hub_ssh_user             = module.hub.ssh_user
#   }
#   gw_proxy_info = {
#     proxy_address              = module.hub.public_ip
#     proxy_private_ssh_key_path = module.key_pair.private_key_file_path
#     proxy_ssh_user             = module.hub.ssh_user
#   }
#   depends_on = [
#     module.hub,
#     module.agentless_gw_group,
#   ]
# }

# module "rds_mysql" {
#   count                        = contains(var.db_types_to_onboard, "RDS MySQL") ? 1 : 0
#   source                       = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mysql-db"
#   version                      = "1.3.9" # latest release tag
#   rds_subnet_ids               = local.db_subnets
#   security_group_ingress_cidrs = local.workstation_cidr
# }

# # create a RDS SQL Server DB
# module "rds_mssql" {
#   count                        = contains(var.db_types_to_onboard, "RDS MsSQL") ? 1 : 0
#   source                       = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mssql-db"
#   version                      = "1.3.9" # latest release tag
#   rds_subnet_ids               = local.db_subnets
#   security_group_ingress_cidrs = local.workstation_cidr

#   providers = {
#     aws                       = aws,
#     aws.poc_scripts_s3_region = aws.poc_scripts_s3_region
#   }
# }

# module "db_onboarding" {
#   for_each      = { for idx, val in concat(module.rds_mysql, module.rds_mssql) : idx => val }
#   source        = "imperva/dsf-poc-db-onboarder/aws"
#   version       = "1.3.9" # latest release tag
#   sonar_version = module.globals.tarball_location.version
#   hub_info = {
#     hub_ip_address           = module.hub.public_ip
#     hub_private_ssh_key_path = module.key_pair.private_key_file_path
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
#     db_address    = each.value.db_address
#     db_engine     = each.value.db_engine
#     db_name       = try(each.value.db_name, null)
#   }
#   depends_on = [
#     module.federation,
#     module.rds_mysql,
#     module.rds_mssql
#   ]
# }
