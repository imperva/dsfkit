provider "aws" {
}

# This provider is used to get MSSQL script files located in eDSF Kit's S3 bucket in the specified region in order to
# generate dummy queries for POC purposes.
# The specified region does not have to be the same as the region where the deployment is taking place.
provider "aws" {
  region = "us-east-1"
  alias  = "poc_scripts_s3_region"
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.7.31" # latest release tag
  sonar_version = var.sonar_version
}

module "key_pair" {
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.7.31" # latest release tag
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
  password           = var.password != null ? var.password : module.globals.random_password
  workstation_cidr   = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tarball_location   = var.tarball_location != null ? var.tarball_location : module.globals.tarball_location
  tags               = merge(module.globals.tags, var.additional_tags, { "deployment_name" = local.deployment_name_salted })
  main_hub_subnet_id = var.subnet_ids != null ? var.subnet_ids.main_hub_subnet_id : module.vpc[0].public_subnets[0]
  dr_hub_subnet_id   = var.subnet_ids != null ? var.subnet_ids.dr_hub_subnet_id : module.vpc[0].public_subnets[1]
  main_gws_subnet_id = var.subnet_ids != null ? var.subnet_ids.main_gws_subnet_id : module.vpc[0].private_subnets[0]
  dr_gws_subnet_id   = var.subnet_ids != null ? var.subnet_ids.dr_gws_subnet_id : module.vpc[0].private_subnets[1]
  db_subnet_ids      = var.subnet_ids != null ? var.subnet_ids.db_subnet_ids : module.vpc[0].public_subnets
}

data "aws_subnet" "main_hub" {
  id = local.main_hub_subnet_id
}

data "aws_subnet" "dr_hub" {
  id = local.dr_hub_subnet_id
}

data "aws_subnet" "main_gw" {
  id = local.main_gws_subnet_id
}

data "aws_subnet" "dr_gw" {
  id = local.dr_gws_subnet_id
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

##############################
# Generating deployment
##############################
module "hub_main" {
  source  = "imperva/dsf-hub/aws"
  version = "1.7.31" # latest release tag

  friendly_name               = join("-", [local.deployment_name_salted, "hub", "main"])
  instance_type               = var.hub_instance_type
  subnet_id                   = local.main_hub_subnet_id
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
  allowed_hub_cidrs                 = [data.aws_subnet.dr_hub.cidr_block]
  allowed_agentless_gw_cidrs        = [data.aws_subnet.main_gw.cidr_block, data.aws_subnet.dr_gw.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr
  allowed_ssh_cidrs                 = var.allowed_ssh_cidrs
  tags                              = local.tags
  depends_on = [
    module.vpc
  ]
}

module "hub_dr" {
  source  = "imperva/dsf-hub/aws"
  version = "1.7.31" # latest release tag

  friendly_name                = join("-", [local.deployment_name_salted, "hub", "DR"])
  instance_type                = var.hub_instance_type
  subnet_id                    = local.dr_hub_subnet_id
  binaries_location            = local.tarball_location
  password                     = local.password
  ebs                          = var.hub_ebs_details
  attach_persistent_public_ip  = true
  use_public_ip                = true
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.hub_main.sonarw_public_key
  main_node_sonarw_private_key = module.hub_main.sonarw_private_key
  generate_access_tokens       = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_hub_cidrs          = [data.aws_subnet.main_hub.cidr_block]
  allowed_agentless_gw_cidrs = [data.aws_subnet.main_gw.cidr_block, data.aws_subnet.dr_gw.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  allowed_ssh_cidrs          = var.allowed_ssh_cidrs
  tags                       = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_main" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.7.31" # latest release tag
  count   = var.gw_count

  friendly_name         = join("-", [local.deployment_name_salted, "gw", count.index, "main"])
  instance_type         = var.agentless_gw_instance_type
  subnet_id             = local.main_gws_subnet_id
  ebs                   = var.agentless_gw_ebs_details
  binaries_location     = local.tarball_location
  password              = local.password
  hub_sonarw_public_key = module.hub_main.sonarw_public_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.dr_gw.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.main_hub.cidr_block, data.aws_subnet.dr_hub.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  allowed_ssh_cidrs          = var.allowed_ssh_cidrs
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_main.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main.ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_dr" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.7.31" # latest release tag
  count   = var.gw_count

  friendly_name                = join("-", [local.deployment_name_salted, "gw", count.index, "DR"])
  instance_type                = var.agentless_gw_instance_type
  subnet_id                    = local.dr_gws_subnet_id
  ebs                          = var.agentless_gw_ebs_details
  binaries_location            = local.tarball_location
  password                     = local.password
  hub_sonarw_public_key        = module.hub_main.sonarw_public_key
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.agentless_gw_main[count.index].sonarw_public_key
  main_node_sonarw_private_key = module.agentless_gw_main[count.index].sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.main_gw.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.main_hub.cidr_block, data.aws_subnet.dr_hub.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  allowed_ssh_cidrs          = var.allowed_ssh_cidrs
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_main.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main.ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "hub_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.7.31" # latest release tag

  sonar_version       = module.globals.tarball_location.version
  dsf_main_ip         = module.hub_main.public_ip
  dsf_main_private_ip = module.hub_main.private_ip
  dsf_dr_ip           = module.hub_dr.public_ip
  dsf_dr_private_ip   = module.hub_dr.private_ip
  ssh_key_path        = module.key_pair.private_key_file_path
  ssh_user            = module.hub_main.ssh_user
  depends_on = [
    module.hub_main,
    module.hub_dr
  ]
}

module "agentless_gw_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.7.31" # latest release tag
  count   = var.gw_count

  sonar_version       = module.globals.tarball_location.version
  dsf_main_ip         = module.agentless_gw_main[count.index].private_ip
  dsf_main_private_ip = module.agentless_gw_main[count.index].private_ip
  dsf_dr_ip           = module.agentless_gw_dr[count.index].private_ip
  dsf_dr_private_ip   = module.agentless_gw_dr[count.index].private_ip
  ssh_key_path        = module.key_pair.private_key_file_path
  ssh_user            = module.agentless_gw_main[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub_main.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main.ssh_user
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
    hub_ip_address            = module.hub_main.public_ip
    hub_federation_ip_address = module.hub_main.public_ip
    hub_private_ssh_key_path  = module.key_pair.private_key_file_path
    hub_ssh_user              = module.hub_main.ssh_user
  }
  gw_info = {
    gw_ip_address            = each.value.private_ip
    gw_federation_ip_address = each.value.private_ip
    gw_private_ssh_key_path  = module.key_pair.private_key_file_path
    gw_ssh_user              = each.value.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_main.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main.ssh_user
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

    PROXY_CMD='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${module.key_pair.private_key_file_path} -W %h:%p ${module.hub_main.ssh_user}@${module.hub_main.public_ip}'

    # wait for existing replication to finish
    while [[ "$(ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="$PROXY_CMD" -i ${module.key_pair.private_key_file_path} ${each.value.ssh_user}@${each.value.private_ip} 'sudo $JSONAR_BASEDIR/bin/arbiter-setup is-repl-running')" != *"No replication cycle is currently running"* ]]; do
        sleep 10
    done

    # force replication to make sure we are up to date
    ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="$PROXY_CMD" -i ${module.key_pair.private_key_file_path} ${each.value.ssh_user}@${each.value.private_ip} 'sudo $JSONAR_BASEDIR/bin/arbiter-setup run-replication'
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
    hub_ip_address            = module.hub_main.public_ip
    hub_federation_ip_address = module.hub_main.public_ip
    hub_private_ssh_key_path  = module.key_pair.private_key_file_path
    hub_ssh_user              = module.hub_main.ssh_user
  }
  gw_info = {
    gw_ip_address            = each.value.private_ip
    gw_federation_ip_address = each.value.private_ip
    gw_private_ssh_key_path  = module.key_pair.private_key_file_path
    gw_ssh_user              = each.value.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_main.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main.ssh_user
  }
  depends_on = [
    null_resource.force_gw_replication,
  ]
}

module "hub_dr_federation" {
  source  = "imperva/dsf-federation/null"
  version = "1.7.31" # latest release tag

  for_each = {
    for idx, val in concat(module.agentless_gw_main, module.agentless_gw_dr) : idx => val
  }

  hub_info = {
    hub_ip_address            = module.hub_dr.public_ip
    hub_federation_ip_address = module.hub_dr.public_ip
    hub_private_ssh_key_path  = module.key_pair.private_key_file_path
    hub_ssh_user              = module.hub_dr.ssh_user
  }
  gw_info = {
    gw_ip_address            = each.value.private_ip
    gw_federation_ip_address = each.value.private_ip
    gw_private_ssh_key_path  = module.key_pair.private_key_file_path
    gw_ssh_user              = each.value.ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_main.public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main.ssh_user
  }
  depends_on = [
    module.hub_dr,
    module.agentless_gw_main,
    module.agentless_gw_dr,

    module.gw_dr_federation,
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


module "rds_mysql" {
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mysql-db"
  version = "1.7.31" # latest release tag

  count = contains(var.simulation_db_types_for_agentless, "RDS MySQL") ? 1 : 0

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr
  tags                         = local.tags
}

# create a RDS SQL Server DB
module "rds_mssql" {
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mssql-db"
  version = "1.7.31" # latest release tag
  count   = contains(var.simulation_db_types_for_agentless, "RDS MsSQL") ? 1 : 0

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr

  tags = local.tags
  providers = {
    aws                       = aws,
    aws.poc_scripts_s3_region = aws.poc_scripts_s3_region
  }
}

module "rds_postgres" {
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-postgres-db"
  version = "1.7.31" # latest release tag
  count   = contains(var.simulation_db_types_for_agentless, "RDS PostgreSQL") ? 1 : 0

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr
  tags                         = local.tags
}

module "db_onboarding" {
  source   = "imperva/dsf-poc-db-onboarder/aws"
  version  = "1.7.31" # latest release tag
  for_each = { for idx, val in concat(module.rds_mysql, module.rds_mssql, module.rds_postgres) : idx => val }

  usc_access_token = module.hub_main.access_tokens.usc.token
  hub_info = {
    hub_ip_address           = module.hub_main.public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = module.hub_main.ssh_user
  }
  assignee_gw   = module.agentless_gw_main[0].jsonar_uid
  assignee_role = module.agentless_gw_main[0].iam_role
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
    null_resource.sonar_setup_completed,

    module.rds_mysql,
    module.rds_mssql
  ]
}

