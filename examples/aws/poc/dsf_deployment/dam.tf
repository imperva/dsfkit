locals {
  agent_gw_count          = var.enable_dam ? var.agent_gw_count : 0
  gateway_group_name      = "temporaryGatewayGroup"
  create_agent_gw_cluster = local.agent_gw_count >= 2 ? 1 : 0

  agent_gw_cidr_list = [data.aws_subnet.agent_gw.cidr_block]
}

module "mx" {
  source  = "imperva/dsf-mx/aws"
  version = "1.7.16" # latest release tag
  count   = var.enable_dam ? 1 : 0

  friendly_name                     = join("-", [local.deployment_name_salted, "mx"])
  dam_version                       = var.dam_version
  ebs                               = var.mx_ebs_details
  subnet_id                         = local.mx_subnet_id
  license                           = var.dam_license
  key_pair                          = module.key_pair.key_pair.key_pair_name
  secure_password                   = local.password
  mx_password                       = local.password
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_agent_gw_cidrs            = [data.aws_subnet.agent_gw.cidr_block]
  allowed_ssh_cidrs                 = concat(local.workstation_cidr, var.allowed_ssh_cidrs)
  allowed_hub_cidrs                 = local.hub_cidr_list

  hub_details = var.enable_sonar ? {
    address      = coalesce(module.hub_main[0].public_dns, module.hub_main[0].private_dns)
    access_token = module.hub_main[0].access_tokens["archiver"].token
    port         = 8443
  } : null
  attach_persistent_public_ip = true
  large_scale_mode            = var.large_scale_mode.mx

  create_server_group = length(var.simulation_db_types_for_agent) > 0
  tags                = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agent_gw" {
  source  = "imperva/dsf-agent-gw/aws"
  version = "1.7.16" # latest release tag
  count   = local.agent_gw_count

  friendly_name                           = join("-", [local.deployment_name_salted, "agent", "gw", count.index])
  dam_version                             = var.dam_version
  ebs                                     = var.agent_gw_ebs_details
  subnet_id                               = local.agent_gw_subnet_id
  key_pair                                = module.key_pair.key_pair.key_pair_name
  secure_password                         = local.password
  mx_password                             = local.password
  allowed_agent_cidrs                     = [data.aws_subnet.agent_gw.cidr_block]
  allowed_mx_cidrs                        = [data.aws_subnet.mx.cidr_block]
  allowed_ssh_cidrs                       = concat([data.aws_subnet.mx.cidr_block], var.allowed_ssh_cidrs)
  allowed_gw_clusters_cidrs               = [data.aws_subnet.agent_gw.cidr_block]
  management_server_host_for_registration = module.mx[0].private_ip
  management_server_host_for_api_access   = module.mx[0].public_ip
  large_scale_mode                        = var.large_scale_mode.agent_gw
  gateway_group_name                      = local.gateway_group_name
  tags                                    = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agent_gw_cluster_setup" {
  source  = "imperva/dsf-agent-gw-cluster-setup/null"
  version = "1.7.16" # latest release tag
  count   = local.create_agent_gw_cluster

  cluster_name       = join("-", [local.deployment_name_salted, "agent", "gw", "cluster"])
  gateway_group_name = local.gateway_group_name
  mx_details = {
    address  = module.mx[0].public_ip
    port     = 8083
    user     = module.mx[0].web_console_user
    password = local.password
  }
  depends_on = [
    module.agent_gw,
    module.mx
  ]
}
