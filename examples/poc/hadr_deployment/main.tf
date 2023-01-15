provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source = "github.com/imperva/dsfkit//modules/aws/core/globals"
}

module "key_pair" {
  source                   = "github.com/imperva/dsfkit//modules/aws/core/key_pair"
  key_name_prefix          = "imperva-dsf-"
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
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  database_cidr              = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location           = module.globals.tarball_location
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
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
  source                              = "github.com/imperva/dsfkit//modules/aws/hub"
  friendly_name                       = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                           = module.vpc.public_subnets[0]
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  ebs                                 = var.hub_ebs_details
  create_and_attach_public_elastic_ip = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = concat(local.workstation_cidr, ["${module.hub_secondary.private_ip}/32"])
    use_public_ip                           = true
  }
  depends_on = [
    module.vpc
  ]
}

module "hub_secondary" {
  source                              = "github.com/imperva/dsfkit//modules/aws/hub"
  friendly_name                       = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                           = module.vpc.public_subnets[1]
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  ebs                                 = var.hub_ebs_details
  create_and_attach_public_elastic_ip = true
  hadr_secondary_node                 = true
  hadr_main_hub_federation_private_key = module.hub.federation_private_key
  hadr_main_hub_federation_public_key = module.hub.federation_public_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = concat(local.workstation_cidr, ["${module.hub.private_ip}/32"])
    use_public_ip                           = true
  }
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group" {
  count                               = var.gw_count
  source                              = "github.com/imperva/dsfkit//modules/aws/agentless-gw"
  friendly_name                       = join("-", [local.deployment_name_salted, "gw", count.index])
  subnet_id                           = module.vpc.private_subnets[0]
  ebs                                 = var.gw_group_ebs_details
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  hub_federation_public_key           = module.hub.federation_public_key
  create_and_attach_public_elastic_ip = false
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub.private_ip}/32", "${module.hub_secondary.private_ip}/32"])
    use_public_ip         = false
  }
  ingress_communication_via_proxy = {
    proxy_address         = module.hub.public_ip
    proxy_private_ssh_key = try(file(module.key_pair.key_pair_private_pem.filename), "")
    proxy_ssh_user        = module.hub.ssh_user
  }
  depends_on = [
    module.vpc
  ]
}

locals {
  hub_gw_combinations = setproduct(
    [module.hub, module.hub_secondary],
    concat(
      [for idx, val in module.agentless_gw_group : val]
    )
  )
}

module "federation" {
  count  = length(local.hub_gw_combinations)
  source = "github.com/imperva/dsfkit//modules/null/federation"
  gws_info = {
    gw_ip_address           = local.hub_gw_combinations[count.index][1].private_ip
    gw_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
    gw_ssh_user             = local.hub_gw_combinations[count.index][1].ssh_user
  }
  hub_info = {
    hub_ip_address           = local.hub_gw_combinations[count.index][0].public_ip
    hub_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
    hub_ssh_user             = local.hub_gw_combinations[count.index][0].ssh_user
  }
  depends_on = [
    module.hub,
    module.hub_secondary,
    module.agentless_gw_group,
  ]
}

module "hadr" {
  source                       = "github.com/imperva/dsfkit//modules/null/hadr"
  dsf_hub_primary_public_ip    = module.hub.public_ip
  dsf_hub_primary_private_ip   = module.hub.private_ip
  dsf_hub_secondary_public_ip  = module.hub_secondary.public_ip
  dsf_hub_secondary_private_ip = module.hub_secondary.private_ip
  ssh_key_path                 = module.key_pair.key_pair_private_pem.filename
  ssh_user                     = module.hub.ssh_user
  depends_on = [
    module.federation,
    module.hub,
    module.hub_secondary
  ]
}

module "rds_mysql" {
  count                        = 1
  source                       = "github.com/imperva/dsfkit//modules/aws/rds-mysql-db"
  rds_subnet_ids               = module.vpc.public_subnets
  security_group_ingress_cidrs = local.workstation_cidr
}

module "db_onboarding" {
  for_each      = { for idx, val in module.rds_mysql : idx => val }
  source        = "github.com/imperva/dsfkit//modules/aws/poc-db-onboarder"
  sonar_version = module.globals.tarball_location.version
  hub_info = {
    hub_ip_address           = module.hub.public_ip
    hub_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
    hub_ssh_user             = module.hub.ssh_user
  }
  assignee_gw   = module.hub.jsonar_uid
  assignee_role = module.hub.iam_role
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
    module.federation,
    module.hadr,
    module.rds_mysql
  ]
}

module "statistics" {
  source = "github.com/imperva/dsfkit//modules/aws/statistics"
}

output "db_details" {
  value = module.rds_mysql
}
