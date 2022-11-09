provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source              = "../../modules/core/globals"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" { state = "available" }

locals {
  workstation_cidr_24 = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  region           = data.aws_region.current
  deployment_name  = local.deployment_name_salted
  admin_password   = var.admin_password != null ? var.admin_password : module.globals.random_password
  workstation_cidr = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  database_cidr    = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location = {
    "s3_bucket" : var.tarball_s3_bucket
    "s3_key" : var.tarball_s3_key
  }
  tags = merge(module.globals.tags, {"deployment_name" = local.deployment_name})
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = local.deployment_name
  cidr   = var.vpc_ip_range

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  tags            = local.tags
}

##############################
# Generating deployment
##############################

module "hub" {
  source                      = "../../modules/hub"
  name                        = join("-", [local.deployment_name,"hub", "primary"])
  subnet_id                   = module.vpc.public_subnets[0]
  key_pair                    = module.globals.key_pair.key_pair_name
  web_console_sg_ingress_cidr = var.web_console_cidr
  sg_ingress_cidr             = local.workstation_cidr
  tarball_bucket_name         = local.tarball_location.s3_bucket
}

module "agentless_gw" {
  count               = var.gw_count
  source              = "../../modules/gw"
  name                = join("-", [local.deployment_name, "gw", count.index])
  subnet_id           = module.vpc.private_subnets[0]
  key_pair            = module.globals.key_pair.key_pair_name
  sg_ingress_cidr     = concat(local.workstation_cidr, ["${module.hub.private_address}/32"])
  tarball_bucket_name = local.tarball_location.s3_bucket
}

module "hub_install" {
  source                = "../../modules/install"
  admin_password        = local.admin_password
  resource_type         = "hub"
  installation_location = local.tarball_location
  ssh_key_pair_path     = module.globals.key_pair_private_pem.filename
  instance_address      = module.hub.public_address
  name                  = join("-", [local.deployment_name, "hub"])
  sonarw_public_key     = module.hub.sonarw_public_key
  sonarw_secret_name    = module.hub.sonarw_secret.name
}

module "gw_install" {
  for_each              = { for idx, val in module.agentless_gw : idx => val }
  source                = "../../modules/install"
  admin_password        = local.admin_password
  resource_type         = "gw"
  installation_location = local.tarball_location
  ssh_key_pair_path     = module.globals.key_pair_private_pem.filename
  instance_address      = each.value.private_address
  proxy_address         = module.hub.public_address
  name                  = join("-", [local.deployment_name, "gw", each.key])
  sonarw_public_key     = module.hub.sonarw_public_key
  sonarw_secret_name    = module.hub.sonarw_secret.name
}

locals {
  hub_gw_combinations = setproduct(
    [module.hub.public_address],
    concat(
      [for idx, val in module.agentless_gw : val.private_address]
    )
  )
}

module "gw_attachments" {
  count               = length(local.hub_gw_combinations)
  index               = count.index
  source              = "../../modules/gw_attachment"
  gw                  = local.hub_gw_combinations[count.index][1]
  hub                 = local.hub_gw_combinations[count.index][0]
  hub_ssh_key_path    = module.globals.key_pair_private_pem.filename
  installation_source = "${local.tarball_location.s3_bucket}/${local.tarball_location.s3_key}"
  depends_on = [
    module.hub_install,
    module.gw_install,
  ]
}

module "db_onboarding" {
  count                    = 1
  source                   = "../../modules/db_onboarding"
  hub_address              = module.hub.public_address
  hub_ssh_key_path         = module.globals.key_pair_private_pem.filename
  assignee_gw              = module.hub_install.jsonar_uid
  assignee_role            = module.hub.iam_role
  database_sg_ingress_cidr = local.database_cidr
  public_subnets = module.vpc.public_subnets
  deployment_name = local.deployment_name
}

output "db_details" {
  value     = module.db_onboarding
  sensitive = true
}

# module "statistics" {
#   source = "../../modules/statistics"
# }


# resource "time_static" "first_apply_ts" {}

# resource "null_resource" "myip" {
#   triggers = {
#     always_run = "${timestamp()}"
#   }
#   provisioner "local-exec" {
#     command     = "curl http://ipv4.icanhazip.com > myip-${terraform.workspace}"
#     interpreter = ["/bin/bash", "-c"]
#   }
# }

# data "local_file" "myip_file" { # data "http" doesn't work as expected on Terraform cloud platform
#   filename = "myip-${terraform.workspace}"
#   depends_on = [
#     resource.null_resource.myip
#   ]
# }

# resource "random_password" "admin_password" {
#   length  = 15
#   special = false
# }

# resource "random_id" "salt" {
#   byte_length = 2
# }

# data "aws_region" "current" {}

# data "aws_caller_identity" "current" {}

##############################
# Generating ssh key pair
##############################

# module "key_pair" {
#   source             = "terraform-aws-modules/key-pair/aws"
#   key_name_prefix    = "imperva-dsf-"
#   create_private_key = true
# }

# resource "local_sensitive_file" "dsf_ssh_key_file" {
#   content         = module.key_pair.private_key_pem
#   file_permission = 400
#   filename        = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
# }

##############################
# Generating network
##############################
