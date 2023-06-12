provider "aws" {
}

provider "aws" {
  region = "us-east-1"
  alias  = "poc_scripts_s3_region"
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.4.7" # latest release tag
  sonar_version = var.sonar_version
  tags          = local.tags
}

module "key_pair" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.7" # latest release tag
  key_name_prefix          = "imperva-dsf-"
  private_key_filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
  tags                     = local.tags
}

locals {
  workstation_cidr_24 = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  password                = var.password != null ? var.password : module.globals.random_password
  workstation_cidr        = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  database_cidr           = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location        = module.globals.tarball_location
  tags                    = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  primary_hub_subnet_id   = var.subnet_ids != null ? var.subnet_ids.primary_hub_subnet_id : module.vpc[0].public_subnets[0]
  secondary_hub_subnet_id = var.subnet_ids != null ? var.subnet_ids.secondary_hub_subnet_id : module.vpc[0].public_subnets[1]
  primary_gws_subnet_id   = var.subnet_ids != null ? var.subnet_ids.primary_gws_subnet_id : module.vpc[0].private_subnets[0]
  secondary_gws_subnet_id = var.subnet_ids != null ? var.subnet_ids.secondary_gws_subnet_id : module.vpc[0].private_subnets[1]
  db_subnet_ids           = var.subnet_ids != null ? var.subnet_ids.db_subnet_ids : module.vpc[0].public_subnets
}

data "aws_subnet" "primary_hub" {
  id = local.primary_hub_subnet_id
}

data "aws_subnet" "secondary_hub" {
  id = local.secondary_hub_subnet_id
}

data "aws_subnet" "primary_gw" {
  id = local.primary_gws_subnet_id
}

data "aws_subnet" "secondary_gw" {
  id = local.secondary_gws_subnet_id
}

##############################
# Generating network
##############################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

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

##############################
# Generating deployment
##############################
module "hub_primary" {
  source  = "imperva/dsf-hub/aws"
  version = "1.4.7" # latest release tag

  friendly_name               = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                   = local.primary_hub_subnet_id
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
  allowed_hub_cidrs                 = [data.aws_subnet.secondary_hub.cidr_block]
  allowed_agentless_gw_cidrs        = [data.aws_subnet.primary_gw.cidr_block, data.aws_subnet.secondary_gw.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr
  tags                              = local.tags
  depends_on = [
    module.vpc
  ]
}

module "hub_secondary" {
  source  = "imperva/dsf-hub/aws"
  version = "1.4.7" # latest release tag

  friendly_name               = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                   = local.secondary_hub_subnet_id
  binaries_location           = local.tarball_location
  password                    = local.password
  ebs                         = var.hub_ebs_details
  attach_persistent_public_ip = true
  use_public_ip               = true
  hadr_secondary_node         = true
  sonarw_public_key           = module.hub_primary.sonarw_public_key
  sonarw_private_key          = module.hub_primary.sonarw_private_key
  generate_access_tokens      = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_hub_cidrs          = [data.aws_subnet.primary_hub.cidr_block]
  allowed_agentless_gw_cidrs = [data.aws_subnet.primary_gw.cidr_block, data.aws_subnet.secondary_gw.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  tags                       = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group_primary" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.4.7" # latest release tag
  count   = var.gw_count

  friendly_name         = join("-", [local.deployment_name_salted, "gw", count.index, "primary"])
  subnet_id             = local.primary_gws_subnet_id
  ebs                   = var.gw_group_ebs_details
  binaries_location     = local.tarball_location
  password              = local.password
  hub_sonarw_public_key = module.hub_primary.sonarw_public_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.secondary_gw.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.primary_hub.cidr_block, data.aws_subnet.secondary_hub.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_primary.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_primary.ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group_secondary" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.4.7" # latest release tag
  count   = var.gw_count

  friendly_name         = join("-", [local.deployment_name_salted, "gw", count.index, "secondary"])
  subnet_id             = local.secondary_gws_subnet_id
  ebs                   = var.gw_group_ebs_details
  binaries_location     = local.tarball_location
  password              = local.password
  hub_sonarw_public_key = module.hub_primary.sonarw_public_key
  hadr_secondary_node   = true
  sonarw_public_key     = module.agentless_gw_group_primary[count.index].sonarw_public_key
  sonarw_private_key    = module.agentless_gw_group_primary[count.index].sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.primary_gw.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.primary_hub.cidr_block, data.aws_subnet.secondary_hub.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_primary.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_primary.ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "hub_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.4.7" # latest release tag

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.hub_primary.public_ip
  dsf_primary_private_ip   = module.hub_primary.private_ip
  dsf_secondary_ip         = module.hub_secondary.public_ip
  dsf_secondary_private_ip = module.hub_secondary.private_ip
  ssh_key_path             = module.key_pair.private_key_file_path
  ssh_user                 = module.hub_primary.ssh_user
  depends_on = [
    module.hub_primary,
    module.hub_secondary
  ]
}

module "agentless_gw_group_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.4.7" # latest release tag
  count   = var.gw_count

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.agentless_gw_group_primary[count.index].private_ip
  dsf_primary_private_ip   = module.agentless_gw_group_primary[count.index].private_ip
  dsf_secondary_ip         = module.agentless_gw_group_secondary[count.index].private_ip
  dsf_secondary_private_ip = module.agentless_gw_group_secondary[count.index].private_ip
  ssh_key_path             = module.key_pair.private_key_file_path
  ssh_user                 = module.agentless_gw_group_primary[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub_primary.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_primary.ssh_user
  }
  depends_on = [
    module.agentless_gw_group_primary,
    module.agentless_gw_group_secondary
  ]
}

locals {
  hub_gw_combinations = setproduct(
    [module.hub_primary, module.hub_secondary],
    concat(
      [for idx, val in module.agentless_gw_group_primary : val],
      [for idx, val in module.agentless_gw_group_secondary : val]
    )
  )
}

module "federation" {
  source  = "imperva/dsf-federation/null"
  version = "1.4.7" # latest release tag
  count   = length(local.hub_gw_combinations)

  gw_info = {
    gw_ip_address           = local.hub_gw_combinations[count.index][1].private_ip
    gw_private_ssh_key_path = module.key_pair.private_key_file_path
    gw_ssh_user             = local.hub_gw_combinations[count.index][1].ssh_user
  }
  hub_info = {
    hub_ip_address           = local.hub_gw_combinations[count.index][0].public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = local.hub_gw_combinations[count.index][0].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_primary.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_primary.ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_group_hadr
  ]
}

module "rds_mysql" {
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mysql-db"
  version = "1.4.7" # latest release tag
  count   = contains(var.db_types_to_onboard, "RDS MySQL") ? 1 : 0

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr
  tags                         = local.tags
}

# create a RDS SQL Server DB
module "rds_mssql" {
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mssql-db"
  version = "1.4.7" # latest release tag
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
  version  = "1.4.7" # latest release tag
  for_each = { for idx, val in concat(module.rds_mysql, module.rds_mssql) : idx => val }

  sonar_version    = module.globals.tarball_location.version
  usc_access_token = module.hub_primary.access_tokens.usc.token
  hub_info = {
    hub_ip_address           = module.hub_primary.public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = module.hub_primary.ssh_user
  }
  assignee_gw   = module.agentless_gw_group_primary[0].jsonar_uid
  assignee_role = module.agentless_gw_group_primary[0].iam_role
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

