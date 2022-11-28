provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source = "../../modules/core/globals"
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  workstation_cidr_24 = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  admin_password   = var.admin_password != null ? var.admin_password : module.globals.random_password
  workstation_cidr = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  database_cidr    = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location = {
    "s3_bucket" : var.tarball_s3_bucket
    "s3_key" : var.tarball_s3_key
  }
  tags = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}

##############################
# Generating network
##############################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = local.deployment_name_salted
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
  key_pair                      = module.globals.key_pair.key_pair_name
  web_console_sg_ingress_cidr   = var.web_console_cidr
  sg_ingress_cidr               = local.workstation_cidr
  installation_location         = local.tarball_location
  admin_password                = local.admin_password
  ssh_key_pair_path             = module.globals.key_pair_private_pem.filename
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
  key_pair                      = module.globals.key_pair.key_pair_name
  sg_ingress_cidr               = concat(local.workstation_cidr, ["${module.hub.private_address}/32"])
  installation_location         = local.tarball_location
  admin_password                = local.admin_password
  ssh_key_pair_path             = module.globals.key_pair_private_pem.filename
  additional_install_parameters = var.additional_install_parameters
  sonarw_public_key             = module.hub.sonarw_public_key
  sonarw_secret_name            = module.hub.sonarw_secret.name
  proxy_address                 = module.hub.public_address
  ebs_details                   = var.gw_group_ebs_details
  depends_on = [
    module.vpc
  ]
}

module "gw_attachments" {
  for_each            = { for idx, val in module.agentless_gw_group : idx => val }
  source              = "../../modules/gw-attachment"
  gw                  = each.value.private_address
  hub                 = module.hub.public_address
  hub_ssh_key_path    = module.globals.key_pair_private_pem.filename
  installation_source = "${local.tarball_location.s3_bucket}/${local.tarball_location.s3_key}"
  depends_on = [
    module.hub,
    module.agentless_gw_group,
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
  hub_address      = module.hub.public_address
  hub_ssh_key_path = module.globals.key_pair_private_pem.filename
  assignee_gw      = module.hub.jsonar_uid
  assignee_role    = module.hub.iam_role
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
    module.hub,
    module.rds_mysql
  ]
}

module "statistics" {
  source = "../../modules/statistics"
  depends_on = [
    module.gw_attachments
  ]
}

output "db_details" {
  value = module.rds_mysql
}
