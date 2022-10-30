provider "aws" {
  region = local.main_region
  profile = local.main_region_profile
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

provider "aws" {
  region = local.sec_region
  profile = local.sec_region_profile
  alias  = "europe"
}

locals {
  main_region = var.main_region
  main_region_profile = var.main_region_profile
  sec_region = var.sec_region
  sec_region_profile = var.sec_region_profile
  deployment_name   = var.deployment_name
  admin_password = var.admin_password
  salt = substr(module.vpc.vpc_id, -8, -1)
  workstation_cidr = var.workstation_cidr != null ? var.workstation_cidr : format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", data.http.myip.body))
}

##############################
# Generating ssh key pair
##############################

module "key_pair" {
  source             = "terraform-aws-modules/key-pair/aws"
  key_name           = join("-", ["dsf_hub_ssh_key", local.deployment_name])
  create_private_key = true
}

resource "local_sensitive_file" "dsf_hub_ssh_key_file" {
  content = module.key_pair.private_key_pem
  file_permission = 400
  filename = "ssh_keys/dsf_hub_ssh_key"
}

resource "aws_key_pair" "hub_ssh_keypair_europe" {
  provider      = aws.europe
  key_name      = module.key_pair.key_pair_name
  public_key    = module.key_pair.public_key_openssh
}

##############################
# Generating network
##############################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.deployment_name
  cidr = "10.0.0.0/16"

  azs             = ["${local.main_region}a", "${local.main_region}b", "${local.main_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = true
}

module "vpc2" {
  source = "terraform-aws-modules/vpc/aws"

  providers         = {
    aws = aws.europe
  }

  name = local.deployment_name
  cidr = "10.0.0.0/16"

  azs             = ["${local.sec_region}a", "${local.sec_region}b", "${local.sec_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = true
}

##############################
# Generating deployment
##############################

module "hub" {
  source            = "../../modules/hub"
  name              = join("-", [local.deployment_name, local.salt])
  subnet_id         = module.vpc.public_subnets[0]
  key_pair          = module.key_pair.key_pair_name
  sg_ingress_cidr   = [local.workstation_cidr]
}

module "hub_install" {
  source                = "../../modules/install"
  admin_password        = local.admin_password # this can't be changed
  dsf_type              = "hub"
  installation_location = var.tarball_location
  ssh_key_pair_path     = local_sensitive_file.dsf_hub_ssh_key_file.filename
  instance_address      = module.hub.public_address
  name                  = join("-", [local.deployment_name, local.salt])
  sonarw_public_key     = module.hub.sonarw_public_key
  sonarw_secret_name    = module.hub.sonarw_secret_name
}

module "agentless_gw" {
  count             = 1
  providers         = {
    aws = aws.europe
  }
  source            = "../../modules/gw"
  name              = join("-", [local.deployment_name, local.salt])
  subnet_id         = module.vpc2.public_subnets[0]
  key_pair          = module.key_pair.key_pair_name
  sg_ingress_cidr   = [local.workstation_cidr, "${module.hub.public_address}/32"]
  public_ip         = true
}

module "gw_install" {
  for_each              = { for idx, val in module.agentless_gw : idx => val }
  source                = "../../modules/install"
  admin_password        = local.admin_password
  dsf_type              = "gw"
  installation_location = var.tarball_location
  ssh_key_pair_path     = local_sensitive_file.dsf_hub_ssh_key_file.filename
  instance_address      = each.value.public_address
  name                  = join("-", [local.deployment_name, local.salt])
  sonarw_public_key     = module.hub.sonarw_public_key
  sonarw_secret_name    = module.hub.sonarw_secret_name
}

module "gw_attachment" {
  for_each         = { for idx, val in module.agentless_gw : idx => val }
  source           = "../../modules/gw_attachment"
  gw               = each.value.public_address
  hub              = module.hub.public_address
  hub_ssh_key_path  = resource.local_sensitive_file.dsf_hub_ssh_key_file.filename
  depends_on = [
    module.hub_install,
    module.gw_install
  ]
  # Re-run this after upgrade
}