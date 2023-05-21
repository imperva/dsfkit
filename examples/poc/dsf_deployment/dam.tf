locals {
  gateway_group_name = "gatewayGroup1"
  agent_gw_count     = var.enable_dsf_mx ? var.agent_gw_count : 0
}

module "mx" {
  source  = "imperva/dsf-mx/aws"
  version = "1.4.5" # latest release tag
  count   = var.enable_dsf_mx ? 1 : 0

  friendly_name                     = join("-", [local.deployment_name_salted, "mx"])
  dam_version                       = var.dam_version
  subnet_id                         = local.mx_subnet_id
  license_file                      = var.license_file
  key_pair                          = module.key_pair.key_pair.key_pair_name
  secure_password                   = local.password
  mx_password                       = local.password
  allowed_web_console_and_api_cidrs = local.workstation_cidr
  allowed_agent_gw_cidrs            = [data.aws_subnet.agent_gw.cidr_block]
  allowed_ssh_cidrs                 = local.workstation_cidr
  hub_details = var.enable_dsf_hub ? {
    address      = module.hub[0].private_ip
    access_token = module.hub[0].access_tokens["dam-to-hub"].token
    port         = 8443
  } : null
  attach_persistent_public_ip = true
  large_scale_mode            = var.large_scale_mode

  create_service_group = var.agent_count > 0 ? true : false
  tags                 = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agent_gw" {
  source  = "imperva/dsf-agent-gw/aws"
  version = "1.4.5" # latest release tag
  count   = local.agent_gw_count

  friendly_name                           = join("-", [local.deployment_name_salted, "agent", "gw", count.index])
  dam_version                             = var.dam_version
  subnet_id                               = local.agent_gw_subnet_id
  key_pair                                = module.key_pair.key_pair.key_pair_name
  secure_password                         = local.password
  mx_password                             = local.password
  allowed_agent_cidrs                     = [data.aws_subnet.agent_gw.cidr_block]
  allowed_mx_cidrs                        = [data.aws_subnet.mx.cidr_block]
  allowed_ssh_cidrs                       = [data.aws_subnet.mx.cidr_block]
  management_server_host_for_registration = module.mx.private_ip
  management_server_host_for_api_access   = module.mx.public_ip
  large_scale_mode                        = var.large_scale_mode
  gateway_group_name                      = local.gateway_group_name
  tags                                    = local.tags
  depends_on = [
    module.vpc
  ]
}
