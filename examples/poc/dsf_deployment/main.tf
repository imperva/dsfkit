provider "aws" {
}

provider "aws" {
  region = "us-east-1"
  alias  = "poc_scripts_s3_region"
}

module "globals" {
  source  = "imperva/dsf-globals/aws"
  version = "1.4.5" # latest release tag

  sonar_version = var.sonar_version
  tags          = local.tags
}

module "key_pair" {
  source  = "imperva/dsf-globals/aws//modules/key_pair"
  version = "1.4.5" # latest release tag

  key_name_prefix          = "imperva-dsf-"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
  tags                     = local.tags
}

locals {
  workstation_cidr_24    = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
  password               = var.password != null ? var.password : module.globals.random_password
  workstation_cidr       = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tags                   = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}
