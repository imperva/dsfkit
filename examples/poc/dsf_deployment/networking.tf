locals {
  hub_subnet_id             = var.subnet_ids != null ? var.subnet_ids.hub_subnet_id : module.vpc[0].public_subnets[0]
  hub_dr_subnet_id          = var.subnet_ids != null ? var.subnet_ids.hub_dr_subnet_id : module.vpc[0].public_subnets[1]
  agentless_gw_subnet_id    = var.subnet_ids != null ? var.subnet_ids.agentless_gw_subnet_id : module.vpc[0].private_subnets[0]
  agentless_gw_dr_subnet_id = var.subnet_ids != null ? var.subnet_ids.agentless_gw_dr_subnet_id : module.vpc[0].private_subnets[1]
  db_subnet_ids             = var.subnet_ids != null ? var.subnet_ids.db_subnet_ids : module.vpc[0].public_subnets
  mx_subnet_id              = var.subnet_ids != null ? var.subnet_ids.mx_subnet_id : module.vpc[0].public_subnets[0]
  dra_admin_subnet_id       = var.subnet_ids != null ? var.subnet_ids.dra_admin_subnet_id : module.vpc[0].public_subnets[0]
  dra_analytics_subnet_id   = var.subnet_ids != null ? var.subnet_ids.dra_analytics_subnet_id : module.vpc[0].private_subnets[0]
  agent_gw_subnet_id        = var.subnet_ids != null ? var.subnet_ids.agent_gw_subnet_id : module.vpc[0].private_subnets[0]
}

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

data "aws_subnet" "hub" {
  id = local.hub_subnet_id
}

data "aws_subnet" "hub_dr" {
  id = local.hub_dr_subnet_id
}

data "aws_subnet" "agentless_gw" {
  id = local.agentless_gw_subnet_id
}

data "aws_subnet" "agentless_gw_dr" {
  id = local.agentless_gw_dr_subnet_id
}

data "aws_subnet" "mx" {
  id = local.mx_subnet_id
}

data "aws_subnet" "agent_gw" {
  id = local.agent_gw_subnet_id
}

data "aws_subnet" "dra_admin" {
  id = local.dra_admin_subnet_id
}

data "aws_subnet" "dra_analytics" {
  id = local.dra_analytics_subnet_id
}
