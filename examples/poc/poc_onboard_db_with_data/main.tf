provider "aws" {
  default_tags {
    tags = local.tags
  }
  #  alias = "default"
}

provider "aws" {
  region = "us-east-1"
  alias = "prod_s3_region"
}

module "globals" {
  source = "../../../modules/aws/core/globals"
}

locals {
  workstation_cidr_24 = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  tags                         = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  workstation_cidr             = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  db_audit_scripts_bucket_name = "ae309159-115c-4504-b0c2-03dd022f3368"
  # change the salt
  #  created_db_name = join("-", [var.onboarded_db_types.db_identifier, module.globals.salt])
  #  created_cluster_identifier = join("-", [var.onboarded_db_types.db_identifier, module.globals.salt])
}

data "aws_region" "current" {}

data "terraform_remote_state" "basic_deployment" {
  backend = "local"
  config = {
    path = "${path.module}/../basic_deployment/terraform.tfstate"
  }
}

# On se demo add outputs of the network – public + private subnet, vpc (private + public?) and used it when uploading the DB

# create a RDS SQL Server DB
module "rds_mssql" {
  count                        = 1
  source                       = "../../../modules/aws/rds-mssql-db"
  db_audit_scripts_bucket_name = local.db_audit_scripts_bucket_name
  #  use the step in se-demo
  rds_subnet_ids               = data.terraform_remote_state.basic_deployment.outputs.dsf_vpc_subnet.public_subnets
  security_group_ingress_cidrs = local.workstation_cidr
  friendly_name                = local.deployment_name_salted
  #  role_arn                     = ""

  providers = {
    aws                 = aws,
    #    aws.default        = aws.default
    aws.prod_s3_region = aws.prod_s3_region
    #    aws.src = aws.prod_s3_region
  }
}

module "db_onboarding" {
  for_each      = { for idx, val in module.rds_mssql : idx => val }
  source        = "../../../modules/aws/poc-db-onboarder"
  sonar_version = module.globals.tarball_location.version
  hub_info = {
    hub_ip_address           = data.terraform_remote_state.basic_deployment.outputs.dsf_hubs.primary.public_ip
    # TODO sivan - change path when move it to basic_deployment
    hub_private_ssh_key_path = "../basic_deployment/${data.terraform_remote_state.basic_deployment.outputs.dsf_private_ssh_key_file_name}"
    hub_ssh_user             = "ec2-user"
  }
  assignee_gw   = data.terraform_remote_state.basic_deployment.outputs.dsf_hubs.primary.jsonar_uid
  assignee_role = data.terraform_remote_state.basic_deployment.outputs.dsf_hubs.primary.role_arn
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
    # TODO sivan - add dependency to mysql when move the code to basic_deployment
#    module.federation,
    module.rds_mssql
  ]
}

#output "mssql_db_details" {
#  value = module.rds_mssql
#}

# onboard the rds to the hub / gw


