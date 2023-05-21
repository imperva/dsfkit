provider "aws" { }

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.4.5" # latest release tag
  tags          = local.tags
}

locals {
  deployment_name_salted                = join("-", [var.deployment_name, module.globals.salt])
  workstation_cidr_24                   = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
  workstation_cidr                      = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  admin_analytics_registration_password = var.admin_analytics_registration_password != null ? var.admin_analytics_registration_password : module.globals.random_password
  archiver_password                     = local.admin_analytics_registration_password
  archiver_user                         = var.archiver_user != null ? var.archiver_user : join("-", [var.deployment_name, module.globals.salt, "archiver-user"])
  tags                                  = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  admin_subnet_id                       = var.subnet_ids != null ? var.subnet_ids.admin_subnet_id : module.vpc[0].public_subnets[0]
  analytics_subnet_id                   = var.subnet_ids != null ? var.subnet_ids.analytics_subnet_id : module.vpc[0].private_subnets[0]
}

data "aws_subnet" "admin" {
  id = local.admin_subnet_id
}

data "aws_subnet" "analytics" {
  id = local.analytics_subnet_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  count = var.subnet_ids == null ? 1 : 0

  name = join("-", [local.deployment_name_salted, module.globals.current_user_name])
  cidr = var.vpc_ip_range

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(module.globals.availability_zones, 0, 2)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  map_public_ip_on_launch = true

  tags = local.tags
}

module "key_pair" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.5" # latest release tag
  key_name_prefix          = "imperva-dsf-dra-"
  private_key_pem_filename = "ssh_keys/dsf_dra_ssh_key-${terraform.workspace}"
  tags                     = local.tags
}

module "dra_admin" {
  source                                = "../../../modules/aws/dra/dra-admin"
  friendly_name                         = join("-", [local.deployment_name_salted, "admin"])
  subnet_id                             = local.admin_subnet_id
  ami                                   = var.admin_ami
  ebs                                   = var.admin_ebs_details
  admin_analytics_registration_password = local.admin_analytics_registration_password
  allowed_web_console_cidrs             = local.workstation_cidr
  allowed_analytics_server_cidrs        = [data.aws_subnet.analytics.cidr_block]
  allowed_ssh_cidrs                     = var.allowed_ssh_cidrs_to_admin
  instance_type                         = var.admin_instance_type
  attach_persistent_public_ip           = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  tags                                  = local.tags
  depends_on = [
    module.vpc
  ]
}

module "analytics_server_group" {
  count                                     = var.analytics_server_count
  source                                    = "../../../modules/aws/dra/dra-analytics"
  friendly_name                             = join("-", [local.deployment_name_salted, "analytics-server", count.index])
  subnet_id                                 = local.analytics_subnet_id
  ami                                       = var.analytics_ami
  ebs                                       = var.analytics_group_ebs_details
  admin_analytics_registration_password_arn = module.dra_admin.admin_analytics_registration_password_secret_arn
  allowed_admin_server_cidrs                = [data.aws_subnet.admin.cidr_block]
  allowed_ssh_cidrs                         = var.allowed_ssh_cidrs_to_analytics
  instance_type                             = var.analytics_instance_type
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  archiver_user                             = local.archiver_user
  archiver_password                         = local.archiver_password
  admin_server_private_ip                   = module.dra_admin.private_ip
  admin_server_public_ip                    = module.dra_admin.public_ip
  tags                                      = local.tags
  depends_on = [
    module.vpc
  ]
}
