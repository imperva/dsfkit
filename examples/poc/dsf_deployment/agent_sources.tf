locals {
  db_types_for_agent = local.create_agent_gw_cluster > 0 ? var.simulation_db_types_for_agent : []
}

module "db_with_agent" {
  source  = "imperva/dsf-db-with-agent/aws"
  version = "1.5.5" # latest release tag
  count   = length(local.db_types_for_agent)

  friendly_name = join("-", [local.deployment_name_salted, "db", "with", "agent", count.index])

  os_type = var.agent_source_os
  db_type = local.db_types_for_agent[count.index]

  subnet_id         = local.agent_gw_subnet_id
  key_pair          = module.key_pair.key_pair.key_pair_name
  allowed_ssh_cidrs = [format("%s/32", module.mx[0].private_ip)]

  registration_params = {
    agent_gateway_host = module.agent_gw[0].private_ip
    secure_password    = local.password
    server_group       = module.mx[0].configuration.default_server_group
    site               = module.mx[0].configuration.default_site
  }
  tags = local.tags
  depends_on = [
    module.agent_gw_cluster_setup
  ]
}
