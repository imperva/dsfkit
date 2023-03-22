provider "aws" {
  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "poc_scripts_s3_region"
}

module "globals" {
  source        = "../../../modules/aws/core/globals"
  tarball_s3_key = "jsonar-4.11.deployfix_20230315022400.tar.gz"
}

module "key_pair" {
  source                   = "../../../modules/aws/core/key_pair"
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
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  database_cidr              = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location           = module.globals.tarball_location
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  primary_hub_subnet         = var.subnet_ids != null ? var.subnet_ids.primary_hub_subnet_id : module.vpc[0].public_subnets[0]
  secondary_hub_subnet       = var.subnet_ids != null ? var.subnet_ids.secondary_hub_subnet_id : module.vpc[0].public_subnets[1]
  primary_gws_subnet         = var.subnet_ids != null ? var.subnet_ids.gw_subnet_id : module.vpc[0].private_subnets[0]
  secondary_gws_subnet       = var.subnet_ids != null ? var.subnet_ids.gw_subnet_id : module.vpc[0].private_subnets[1]
  db_subnets                 = var.subnet_ids != null ? var.subnet_ids.db_subnet_ids : module.vpc[0].public_subnets
}

##############################
# Generating network
##############################

module "vpc" {
  count = var.subnet_ids == null ? 1 : 0

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
module "hub_primary" {
  source                     = "../../../modules/aws/hub"
  friendly_name              = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                  = local.primary_hub_subnet
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  ebs                        = var.hub_ebs_details
  attach_public_ip           = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = concat(local.workstation_cidr, ["${module.hub_secondary.private_ip}/32"], [var.private_subnets[0]])
  }
  use_public_ip = true
  depends_on = [
    module.vpc
  ]
}

module "hub_secondary" {
  source                     = "../../../modules/aws/hub"
  friendly_name              = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                  = local.secondary_hub_subnet
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  ebs                        = var.hub_ebs_details
  attach_public_ip           = true
  hadr_secondary_node        = true
  sonarw_public_key          = module.hub_primary.sonarw_public_key
  sonarw_private_key         = module.hub_primary.sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = concat(local.workstation_cidr, ["${module.hub_primary.private_ip}/32"], [var.private_subnets[0]])
  }
  use_public_ip = true
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group_primary" {
  source                     = "../../../modules/aws/agentless-gw"
  count                      = var.gw_count
  friendly_name              = join("-", [local.deployment_name_salted, "gw", count.index, "primary"])
  subnet_id                  = local.primary_gws_subnet
  ebs                        = var.gw_group_ebs_details
  binaries_location          = local.tarball_location
  web_console_admin_password = local.web_console_admin_password
  hub_sonarw_public_key      = module.hub_primary.sonarw_public_key
  attach_public_ip           = false
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub_primary.private_ip}/32", "${module.hub_secondary.private_ip}/32"])
  }
  use_public_ip = false
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_primary.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_primary.ssh_user
  }
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group_secondary" {
  source                              = "../../../modules/aws/agentless-gw"
  count                               = var.gw_count
  friendly_name                       = join("-", [local.deployment_name_salted, "gw", count.index, "secondary"])
  subnet_id                           = local.secondary_gws_subnet
  ebs                                 = var.gw_group_ebs_details
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  hub_sonarw_public_key               = module.hub_primary.sonarw_public_key
  hadr_secondary_node                 = true
  sonarw_public_key                   = module.agentless_gw_group_primary[count.index].sonarw_public_key
  sonarw_private_key                  = module.agentless_gw_group_primary[count.index].sonarw_private_key
  create_and_attach_public_elastic_ip = false
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub_primary.private_ip}/32", "${module.hub_secondary.private_ip}/32", "${module.agentless_gw_group_primary[count.index].private_ip}/32"])
  }
  use_public_ip = false
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_primary.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_primary.ssh_user
  }
  depends_on = [
    module.vpc
  ]
}

# assumes that ingress_ports output of all gateways is the same
locals {
  primary_gw_sg_and_secondary_gw_ip_combinations = setproduct(
    [for idx, gw in module.agentless_gw_group_primary: gw.sg_id],
    [for idx, gw in module.agentless_gw_group_secondary: gw.private_ip],
    [for idx, ingress_port in module.agentless_gw_group_secondary[0].ingress_ports : ingress_port]
  )
}

locals {
  # Combinations of primary GW security group Id with the corresponding secondary GW IP.
  # For example, if we have 2 GWs, the combinations would be something like:
  # [{ primary_sg = gw0_primary_sg, secondary_ip = gw0_secondary_ip }]
  # [{ primary_sg = gw1_primary_sg, secondary_ip = gw1_secondary_ip }]
  sg_ip_combinations = [for idx, gw in module.agentless_gw_group_primary: {
    primary_sg = module.agentless_gw_group_primary[idx].sg_id
    secondary_ip = module.agentless_gw_group_secondary[idx].private_ip
  }]

  # Combinations of primary GW security group Id with the corresponding secondary GW IP x ingress ports.
  # For example, if we have 2 GWs and 2 ingress ports, the combinations would be something like:
  # [{ primary_sg = gw0_primary_sg, secondary_ip = gw0_secondary_ip }, port0]
  # [{ primary_sg = gw0_primary_sg, secondary_ip = gw0_secondary_ip }, port1]
  # [{ primary_sg = gw1_primary_sg, secondary_ip = gw1_secondary_ip }, port0]
  # [{ primary_sg = gw1_primary_sg, secondary_ip = gw1_secondary_ip }, port1]
  sg_ip_port_combinations = setproduct(
    [for idx, sg_ip in local.sg_ip_combinations: sg_ip],
    # assumes that ingress_ports output of all gateways is the same
    [for idx, ingress_port in module.agentless_gw_group_primary[0].ingress_ports : ingress_port]
  )
}

# Adds secondary GW CIDR to ingress CIDRs of the primary GW's security group
resource aws_security_group_rule "primary_gw_sg_secondary_cidr_ingress" {
  count             = length(local.sg_ip_port_combinations)
  type              = "ingress"
  from_port         = local.sg_ip_port_combinations[count.index][1]
  to_port           = local.sg_ip_port_combinations[count.index][1]
  protocol          = "tcp"
  cidr_blocks       = ["${local.sg_ip_port_combinations[count.index][0].secondary_ip}/32"]
  security_group_id = local.sg_ip_port_combinations[count.index][0].primary_sg
}

module "hub_hadr" {
  source                   = "../../../modules/null/hadr"
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
  count                        = var.gw_count
  source                       = "../../../modules/null/hadr"
  dsf_primary_ip               = module.agentless_gw_group_primary[count.index].private_ip
  dsf_primary_private_ip       = module.agentless_gw_group_primary[count.index].private_ip
  dsf_secondary_ip             = module.agentless_gw_group_secondary[count.index].private_ip
  dsf_secondary_private_ip     = module.agentless_gw_group_secondary[count.index].private_ip
  ssh_key_path                 = module.key_pair.private_key_file_path
  ssh_user                     = module.agentless_gw_group_primary[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub_primary.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_primary.ssh_user
  }
  depends_on = [
    module.agentless_gw_group_primary,
    module.agentless_gw_group_secondary,
    aws_security_group_rule.primary_gw_sg_secondary_cidr_ingress
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
  count   = length(local.hub_gw_combinations)
  source  = "../../../modules/null/federation"
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
  count                        = contains(var.db_types_to_onboard, "RDS MySQL") ? 1 : 0
  source                       = "../../../modules/aws/rds-mysql-db"
  rds_subnet_ids               = local.db_subnets
  security_group_ingress_cidrs = local.workstation_cidr
}

# create a RDS SQL Server DB
module "rds_mssql" {
  count                        = contains(var.db_types_to_onboard, "RDS MsSQL") ? 1 : 0
  source                       = "../../../modules/aws/rds-mssql-db"
  rds_subnet_ids               = local.db_subnets
  security_group_ingress_cidrs = local.workstation_cidr

  providers = {
    aws                       = aws,
    aws.poc_scripts_s3_region = aws.poc_scripts_s3_region
  }
}

module "db_onboarding" {
  for_each      = { for idx, val in concat(module.rds_mysql, module.rds_mssql) : idx => val }
  source        = "../../../modules/aws/poc-db-onboarder"
  sonar_version = module.globals.tarball_location.version
  hub_info = {
    hub_ip_address           = module.hub_primary.public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = module.hub_primary.ssh_user
  }
  assignee_gw   = module.hub_primary.jsonar_uid
  assignee_role = module.hub_primary.iam_role
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
  depends_on = [
    module.federation,
    module.hub_hadr,
    module.agentless_gw_group_hadr,
    module.rds_mysql,
    module.rds_mssql
  ]
}

