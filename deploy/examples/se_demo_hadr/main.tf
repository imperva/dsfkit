provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source = "../../modules/core/globals"
}

module "key_pair" {
  source                   = "../../modules/core/key_pair"
  key_name_prefix          = "imperva-dsf-"
  create_private_key       = true
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  workstation_cidr_24 = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  web_console_admin_password   = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  database_cidr    = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location = module.globals.tarball_location
  tags = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}

##############################
# Generating network
##############################

module "vpc" {
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

module "hub" {
  source                        = "../../modules/hub"
  name                          = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                     = module.vpc.public_subnets[0]
  key_pair                      = module.key_pair.key_pair.key_pair_name
  web_console_cidr              = var.web_console_cidr
  sg_ingress_cidr               = concat(local.workstation_cidr, ["${module.hub_secondary.private_address}/32"])
  binaries_location         = local.tarball_location
  web_console_admin_password                = local.web_console_admin_password
  ssh_key_path                  = module.key_pair.key_pair_private_pem.filename
  additional_install_parameters = var.additional_install_parameters
  ebs_details                   = var.hub_ebs_details
  depends_on = [
    module.vpc
  ]
}

module "hub_secondary" {
  source                        = "../../modules/hub"
  name                          = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                     = module.vpc.public_subnets[1]
  key_pair                      = module.key_pair.key_pair.key_pair_name
  web_console_cidr              = var.web_console_cidr
  sg_ingress_cidr               = concat(local.workstation_cidr, ["${module.hub.private_address}/32"])
  hadr_secondary_node           = true
  hadr_main_hub_sonarw_secret   = module.hub.sonarw_secret
  hadr_main_hub_federation_public_key      = module.hub.federation_public_key
  binaries_location         = local.tarball_location
  web_console_admin_password                = local.web_console_admin_password
  ssh_key_path                  = module.key_pair.key_pair_private_pem.filename
  additional_install_parameters = var.additional_install_parameters
  ebs_details                   = var.hub_ebs_details
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group" {
  count                         = var.gw_count
  source                        = "../../modules/agentless-gw"
  name                          = join("-", [local.deployment_name_salted, "gw", count.index])
  subnet_id                     = module.vpc.private_subnets[0]
  key_pair                      = module.key_pair.key_pair.key_pair_name
  sg_ingress_cidr               = concat(local.workstation_cidr, ["${module.hub.private_address}/32", "${module.hub_secondary.private_address}/32"])
  binaries_location         = local.tarball_location
  web_console_admin_password                = local.web_console_admin_password
  ssh_key_path                  = module.key_pair.key_pair_private_pem.filename
  additional_install_parameters = var.additional_install_parameters
  hub_federation_public_key             = module.hub.federation_public_key
  proxy_address                 = module.hub.public_address
  ebs_details                   = var.gw_group_ebs_details
  proxy_private_key             = module.hub.federation_public_key
  depends_on = [
    module.vpc
  ]
}

locals {
  hub_gw_combinations = setproduct(
    [module.hub.public_address, module.hub_secondary.public_address],
    concat(
      [for idx, val in module.agentless_gw_group : val.private_address]
    )
  )
}

module "gw_attachments" {
  count               = length(local.hub_gw_combinations)
  source              = "../../modules/gw-attachment"
  gw                  = local.hub_gw_combinations[count.index][1]
  hub                 = local.hub_gw_combinations[count.index][0]
  hub_ssh_key_path    = module.key_pair.key_pair_private_pem.filename
  installation_source = "${local.tarball_location.s3_bucket}/${local.tarball_location.s3_key}"
  gw_ssh_key_path     = module.key_pair.key_pair_private_pem.filename
  depends_on = [
    module.hub,
    module.hub_secondary,
    module.agentless_gw_group,
  ]
}

module "hadr" {
  source                       = "../../modules/hadr"
  dsf_hub_primary_public_ip    = module.hub.public_address
  dsf_hub_primary_private_ip   = module.hub.private_address
  dsf_hub_secondary_public_ip  = module.hub_secondary.public_address
  dsf_hub_secondary_private_ip = module.hub_secondary.private_address
  ssh_key_path                 = module.key_pair.key_pair_private_pem.filename
  depends_on = [
    module.gw_attachments,
    module.hub,
    module.hub_secondary
  ]
}

module "rds_mysql" {
  count                        = 1
  source                       = "../../modules/rds-mysql-db"
  rds_subnet_ids               = module.vpc.public_subnets
  security_group_ingress_cidrs = local.workstation_cidr
}

module "db_onboarding" {
  for_each         = { for idx, val in module.rds_mysql : idx => val }
  source           = "../../modules/db-onboarder"
  sonar_version    = module.globals.tarball_location.version
  hub_address      = module.hub.public_address
  hub_ssh_key_path = module.key_pair.key_pair_private_pem.filename
  assignee_gw      = module.agentless_gw_group[0].jsonar_uid
  assignee_role    = module.agentless_gw_group[0].iam_role
  database_details = {
    db_username   = each.value.db_username
    db_password   = each.value.db_password
    db_arn        = each.value.db_arn
    db_port       = each.value.db_port
    db_identifier = each.value.db_identifier
    db_address    = each.value.db_endpoint
    db_engine     = each.value.db_engine
  }
  depends_on = [
    module.gw_attachments,
    module.hadr,
    module.rds_mysql
  ]
}

module "statistics" {
  source = "../../modules/statistics"
}

output "db_details" {
  value = module.rds_mysql
}
