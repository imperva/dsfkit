locals {
  agent_count = local.agent_gw_count > 0 ? var.agent_count : 0
}

module "agent_monitored_db" {
  source  = "imperva/dsf-db-with-agent/aws"
  version = "1.4.6" # latest release tag
  count   = local.agent_count

  friendly_name = join("-", [local.deployment_name_salted, "agent", "monitored", "db", count.index])

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
