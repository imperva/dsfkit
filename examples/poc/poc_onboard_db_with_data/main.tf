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
  source = "../../modules/core/globals"
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
  source                       = "../../modules/rds-mssql-db"
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

#output "mssql_db_details" {
#  value = module.rds_mssql
#}

# onboard the rds to the hub / gw


