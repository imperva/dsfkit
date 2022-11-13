locals {
  region           = data.aws_region.current.name
  deployment_name  = join("-", [var.deployment_name, random_id.salt.hex])
  admin_password   = var.admin_password != null ? var.admin_password : random_password.admin_password.result
  workstation_cidr = var.workstation_cidr != null ? var.workstation_cidr : [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", data.local_file.myip_file.content))]
  database_cidr    = var.database_cidr != null ? var.database_cidr : [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", data.local_file.myip_file.content))]
  tarball_location = {
    s3_bucket = var.artifacts_s3_bucket
    s3_key = var.tarball_s3_key
  }
  tags = {
    deployment_name                    = local.deployment_name
    terraform_workspace                = terraform.workspace
    vendor                             = "Imperva"
    product                            = "EDSF"
    terraform                          = "true"
    environment                        = "demo"
    creation_timestamp                 = time_static.first_apply_ts.id
  }
}

provider "aws" {
  default_tags {
    tags = local.tags
  }
}

resource "time_static" "first_apply_ts" {}

resource "null_resource" "myip" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command     = "curl http://ipv4.icanhazip.com > myip-${terraform.workspace}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command     = "rm -f myip-${terraform.workspace}"
    interpreter = ["/bin/bash", "-c"]
    when = destroy
  }

}

data "local_file" "myip_file" { # data sources (like "http") doesn't work as expected on Terraform cloud platform. They are being run on another host resulting the wrong IP address
  filename = "myip-${terraform.workspace}"
  depends_on = [
    resource.null_resource.myip
  ]
}

resource "random_password" "admin_password" {
  length  = 15
  special = false
}

resource "random_id" "salt" {
  byte_length = 2
}

data "aws_region" "current" {}

##############################
# Generating ssh key pair
##############################

module "key_pair" {
  source             = "terraform-aws-modules/key-pair/aws"
  key_name_prefix    = "imperva-dsf-"
  create_private_key = true
}

resource "local_sensitive_file" "dsf_ssh_key_file" {
  content         = module.key_pair.private_key_pem
  file_permission = 400
  filename        = "ssh_keys/dsf_hub_ssh_key-${terraform.workspace}"
}

##############################
# Generating network
##############################

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = local.deployment_name
  cidr   = "10.0.0.0/16"

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  # tags            = local.tags
}

##############################
# Generating deployment
##############################

module "hub" {
  source                      = "../../modules/hub"
  name                        = join("-", [local.deployment_name, "hub", "primary"])
  subnet_id                   = module.vpc.public_subnets[0]
  key_pair                    = module.key_pair.key_pair_name
  web_console_sg_ingress_cidr = var.web_console_cidr
  sg_ingress_cidr             = local.workstation_cidr
  installation_location       = local.tarball_location
  admin_password              = local.admin_password
  ssh_key_pair_path           = local_sensitive_file.dsf_ssh_key_file.filename
  additional_install_parameters = var.additional_install_parameters
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw" {
  count               = var.gw_count
  source              = "../../modules/agentless-gw"
  name                = join("-", [local.deployment_name, "gw", count.index])
  subnet_id           = module.vpc.private_subnets[0]
  key_pair            = module.key_pair.key_pair_name
  sg_ingress_cidr     = concat(local.workstation_cidr, ["${module.hub.private_address}/32"])
  installation_location = local.tarball_location
  admin_password      = local.admin_password
  ssh_key_pair_path   = local_sensitive_file.dsf_ssh_key_file.filename
  additional_install_parameters = var.additional_install_parameters
  sonarw_public_key   = module.hub.sonarw_public_key
  sonarw_secret_name  = module.hub.sonarw_secret.name
  proxy_address       = module.hub.public_address
  depends_on = [
    module.vpc
  ]
}

module "gw_attachments" {
  for_each              = { for idx, val in module.agentless_gw : idx => val }
  source              = "../../modules/gw-attachment"
  gw                  = each.value.private_address
  hub                 = module.hub.public_address
  hub_ssh_key_path    = resource.local_sensitive_file.dsf_ssh_key_file.filename
  installation_source = "${local.tarball_location.s3_bucket}/${local.tarball_location.s3_key}"
  depends_on = [
    module.hub,
    module.agentless_gw,
  ]
}

module "rds_mysql" {
  source  = "../../modules/rds-mysql-db"
  rds_subnet_ids = module.vpc.public_subnets
  security_group_ingress_cidrs = local.workstation_cidr
}

module "db_onboarding" {
  count                    = 1
  source                   = "../../modules/db-onboarder"
  hub_address              = module.hub.public_address
  hub_ssh_key_path         = local_sensitive_file.dsf_ssh_key_file.filename
  assignee_gw              = module.hub.jsonar_uid
  assignee_role            = module.hub.iam_role
  database_details = {
    db_username = module.rds_mysql.db_username
    db_password = module.rds_mysql.db_password
    db_arn = module.rds_mysql.db_arn
    db_port = module.rds_mysql.db_port
    db_identifier = module.rds_mysql.db_identifier
    db_address = module.rds_mysql.db_endpoint
    db_engine = module.rds_mysql.db_engine
  }
  depends_on = [
    module.hub,
    module.rds_mysql
  ]
}

output "db_details" {
  value     = module.rds_mysql
  sensitive = true
}
