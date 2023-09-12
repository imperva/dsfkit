provider "aws" {
}

provider "aws" {
  region = "us-east-1"
  alias  = "poc_scripts_s3_region"
}

module "globals" {
  source  = "imperva/dsf-globals/aws"
  version = "1.5.4" # latest release tag

  sonar_version = var.sonar_version
}

module "key_pair" {
  source  = "imperva/dsf-globals/aws//modules/key_pair"
  version = "1.5.4" # latest release tag

  key_name_prefix      = "imperva-dsf-"
  private_key_filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
  tags                 = local.tags
}

locals {
  workstation_cidr_24 = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  password         = var.password != null ? var.password : module.globals.random_password
  workstation_cidr = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  database_cidr    = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location = module.globals.tarball_location
  tags             = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  hub_subnet_id    = var.subnet_ids != null ? var.subnet_ids.hub_subnet_id : module.vpc[0].public_subnets[0]
  gw_subnet_id     = var.subnet_ids != null ? var.subnet_ids.gw_subnet_id : module.vpc[0].private_subnets[0]
  db_subnet_ids    = var.subnet_ids != null ? var.subnet_ids.db_subnet_ids : module.vpc[0].public_subnets
}

##############################
# Generating network
##############################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  count = var.subnet_ids == null ? 1 : 0

  name = "${local.deployment_name_salted}-${module.globals.current_user_name}"
  cidr = var.vpc_ip_range

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(module.globals.availability_zones, 0, 2)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  map_public_ip_on_launch = true
  tags                    = local.tags
}

data "aws_subnet" "hub" {
  id = local.hub_subnet_id
}

data "aws_subnet" "gw" {
  id = local.gw_subnet_id
}

##############################
# Generating deployment
##############################

module "hub" {
  source  = "imperva/dsf-hub/aws"
  version = "1.5.4" # latest release tag

  friendly_name               = join("-", [local.deployment_name_salted, "hub"])
  instance_type               = var.hub_instance_type
  subnet_id                   = local.hub_subnet_id
  binaries_location           = local.tarball_location
  password                    = local.password
  ebs                         = var.hub_ebs_details
  attach_persistent_public_ip = true
  use_public_ip               = true
  generate_access_tokens      = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_agentless_gw_cidrs        = [data.aws_subnet.gw.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr
  tags                              = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.5.4" # latest release tag
  count   = var.gw_count

  friendly_name         = join("-", [local.deployment_name_salted, "gw", count.index])
  instance_type         = var.agentless_gw_instance_type
  subnet_id             = local.gw_subnet_id
  ebs                   = var.agentless_gw_ebs_details
  binaries_location     = local.tarball_location
  password              = local.password
  hub_sonarw_public_key = module.hub.sonarw_public_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_hub_cidrs = [data.aws_subnet.hub.cidr_block]
  allowed_all_cidrs = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub.ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc,
  ]
}

module "federation" {
  source   = "imperva/dsf-federation/null"
  version  = "1.5.4" # latest release tag
  for_each = { for idx, val in module.agentless_gw : idx => val }

  hub_info = {
    hub_ip_address           = module.hub.public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = module.hub.ssh_user
  }
  gw_info = {
    gw_ip_address           = each.value.private_ip
    gw_private_ssh_key_path = module.key_pair.private_key_file_path
    gw_ssh_user             = each.value.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.hub,
    module.agentless_gw,
  ]
}

module "rds_mysql" {
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mysql-db"
  version = "1.5.4" # latest release tag
  count   = contains(var.db_types_to_onboard, "RDS MySQL") ? 1 : 0

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr
  tags                         = local.tags
}

module "rds_mssql" {
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mssql-db"
  version = "1.5.4" # latest release tag
  count   = contains(var.db_types_to_onboard, "RDS MsSQL") ? 1 : 0

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr

  tags = local.tags
  providers = {
    aws                       = aws,
    aws.poc_scripts_s3_region = aws.poc_scripts_s3_region
  }
}

module "db_onboarding" {
  source   = "imperva/dsf-poc-db-onboarder/aws"
  version  = "1.5.4" # latest release tag
  for_each = { for idx, val in concat(module.rds_mysql, module.rds_mssql) : idx => val }

  sonar_version    = module.globals.tarball_location.version
  usc_access_token = module.hub.access_tokens.usc.token
  hub_info = {
    hub_ip_address           = module.hub.public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = module.hub.ssh_user
  }

  assignee_gw   = module.agentless_gw[0].jsonar_uid
  assignee_role = module.agentless_gw[0].iam_role
  database_details = {
    db_username   = each.value.db_username
    db_password   = each.value.db_password
    db_arn        = each.value.db_arn
    db_port       = each.value.db_port
    db_identifier = each.value.db_identifier
    db_address    = each.value.db_address
    db_engine     = each.value.db_engine
    db_name       = try(each.value.db_name, null)
  }
  tags = local.tags
  depends_on = [
    module.federation,
    module.rds_mysql,
    module.rds_mssql
  ]
}
