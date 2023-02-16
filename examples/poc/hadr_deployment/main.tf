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
  source        = "imperva/dsf-globals/aws"
  version       = "1.3.6" # latest release tag
  sonar_version = var.sonar_version
}

module "key_pair" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.6" # latest release tag
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
# TODO rename to hub_primary in another commit
module "hub" {
  source                              = "imperva/dsf-hub/aws"
  version                             = "1.3.6" # latest release tag
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
  source                               = "imperva/dsf-hub/aws"
  version                              = "1.3.6" # latest release tag
  friendly_name                        = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                            = module.vpc.public_subnets[1]
  binaries_location                    = local.tarball_location
  web_console_admin_password           = local.web_console_admin_password
  ebs                                  = var.hub_ebs_details
  create_and_attach_public_elastic_ip  = true
  hadr_secondary_node                  = true
  sonarw_public_key                    = module.hub.sonarw_public_key
  sonarw_private_key                   = module.hub.sonarw_private_key
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

module "agentless_gw_group_primary" {
  count                               = var.gw_count
  source                              = "imperva/dsf-agentless-gw/aws"
  version                             = "1.3.6" # latest release tag
  friendly_name                       = join("-", [local.deployment_name_salted, "gw", count.index, "primary"])
  subnet_id                           = module.vpc.private_subnets[0]
  ebs                                 = var.gw_group_ebs_details
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  hub_sonarw_public_key               = module.hub.sonarw_public_key
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
    proxy_address              = module.hub.public_ip
    proxy_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group_secondary" {
  count                               = var.gw_count
  source                              = "imperva/dsf-agentless-gw/aws"
  version                             = "1.3.6" # latest release tag
  friendly_name                       = join("-", [local.deployment_name_salted, "gw", count.index, "secondary"])
  subnet_id                           = module.vpc.private_subnets[1]
  ebs                                 = var.gw_group_ebs_details
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  hub_sonarw_public_key               = module.hub.sonarw_public_key
  hadr_secondary_node                 = true
  sonarw_public_key                   = module.agentless_gw_group_primary[count.index].sonarw_public_key
  sonarw_private_key                  = module.agentless_gw_group_primary[count.index].sonarw_private_key
  create_and_attach_public_elastic_ip = false
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub.private_ip}/32", "${module.hub_secondary.private_ip}/32", "${module.agentless_gw_group_primary[count.index].private_ip}/32"])
    use_public_ip         = false
  }
  ingress_communication_via_proxy = {
    proxy_address              = module.hub.public_ip
    proxy_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
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

# adds secondary gw cidr to ingress cidrs of the primary gw's sg
resource aws_security_group_rule "primary_gw_sg_secondary_cidr_ingress" {
  count             = length(local.primary_gw_sg_and_secondary_gw_ip_combinations)
  type              = "ingress"
  from_port         = local.primary_gw_sg_and_secondary_gw_ip_combinations[count.index][2]
  to_port           = local.primary_gw_sg_and_secondary_gw_ip_combinations[count.index][2]
  protocol          = "tcp"
  cidr_blocks       = ["${local.primary_gw_sg_and_secondary_gw_ip_combinations[count.index][1]}/32"]
  security_group_id = local.primary_gw_sg_and_secondary_gw_ip_combinations[count.index][0]
}

module "hub_hadr" {
  source                       = "imperva/dsf-hadr/null"
  version                      = "1.3.6" # latest release tag
  dsf_primary_ip               = module.hub.public_ip
  dsf_primary_private_ip       = module.hub.private_ip
  dsf_secondary_ip             = module.hub_secondary.public_ip
  dsf_secondary_private_ip     = module.hub_secondary.private_ip
  ssh_key_path                 = module.key_pair.key_pair_private_pem.filename
  ssh_user                     = module.hub.ssh_user
  depends_on = [
    module.hub,
    module.hub_secondary
  ]
}

module "agentless_gw_group_hadr" {
  count                        = var.gw_count
  source                       = "imperva/dsf-hadr/null"
  version                      = "1.3.6" # latest release tag
  dsf_primary_ip               = module.agentless_gw_group_primary[count.index].private_ip
  dsf_primary_private_ip       = module.agentless_gw_group_primary[count.index].private_ip
  dsf_secondary_ip             = module.agentless_gw_group_secondary[count.index].private_ip
  dsf_secondary_private_ip     = module.agentless_gw_group_secondary[count.index].private_ip
  ssh_key_path                 = module.key_pair.key_pair_private_pem.filename
  ssh_user                     = module.agentless_gw_group_primary[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub.public_ip
    proxy_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.agentless_gw_group_primary,
    module.agentless_gw_group_secondary,
    aws_security_group_rule.primary_gw_sg_secondary_cidr_ingress
  ]
}

locals {
  hub_gw_combinations = setproduct(
    [module.hub, module.hub_secondary],
    concat(
      [for idx, val in module.agentless_gw_group_primary : val],
      [for idx, val in module.agentless_gw_group_secondary : val]
    )
  )
}

module "federation" {
  count                     = length(local.hub_gw_combinations)
  source                    = "imperva/dsf-federation/null"
  version                   = "1.3.6" # latest release tag
  gw_info = {
    gw_ip_address           = local.hub_gw_combinations[count.index][1].private_ip
    gw_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
    gw_ssh_user             = local.hub_gw_combinations[count.index][1].ssh_user
  }
  hub_info = {
    hub_ip_address           = local.hub_gw_combinations[count.index][0].public_ip
    hub_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
    hub_ssh_user             = local.hub_gw_combinations[count.index][0].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub.public_ip
    proxy_private_ssh_key_path = module.key_pair.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_group_hadr
  ]
}

module "rds_mysql" {
  count                        = contains(var.db_types_to_onboard, "RDS MySQL") ? 1 : 0
  source                       = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mysql-db"
  version                      = "1.3.6" # latest release tag
  rds_subnet_ids               = module.vpc.public_subnets
  security_group_ingress_cidrs = local.workstation_cidr
}

# create a RDS SQL Server DB
module "rds_mssql" {
  count                        = contains(var.db_types_to_onboard, "RDS MsSQL") ? 1 : 0
  source                       = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mssql-db"
  version                      = "1.3.6" # latest release tag
  rds_subnet_ids               = module.vpc.public_subnets
  security_group_ingress_cidrs = local.workstation_cidr

  providers = {
    aws                       = aws,
    aws.poc_scripts_s3_region = aws.poc_scripts_s3_region
  }
}

module "db_onboarding" {
  for_each                   = { for idx, val in concat(module.rds_mysql, module.rds_mssql)  : idx => val }
  source                     = "imperva/dsf-poc-db-onboarder/aws"
  version                    = "1.3.6" # latest release tag
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
    db_address    = each.value.db_address
    db_engine     = each.value.db_engine
    db_name       = try(each.value.db_name, null)
  }
  depends_on = [
    module.federation,
    module.hub_hadr,
    module.agentless_gw_group_hadr, # TODO do we need this?
    module.rds_mysql,
    module.rds_mssql
  ]
}

module "statistics" {
  source  = "imperva/dsf-statistics/aws"
  version = "1.3.6" # latest release tag
}

