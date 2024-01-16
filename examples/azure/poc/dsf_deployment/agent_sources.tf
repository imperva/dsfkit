locals {
  db_types_for_agent = local.agent_gw_count > 0 ? var.simulation_db_types_for_agent : []
}

module "db_with_agent" {
  source  = "imperva/dsf-db-with-agent/azurerm"
  version = "1.7.5" # latest release tag
  count   = length(local.db_types_for_agent)

  friendly_name     = join("-", [local.deployment_name_salted, "db", "with", "agent", count.index])
  resource_group    = local.resource_group
  binaries_location = var.dam_agent_installation_location
  db_type           = local.db_types_for_agent[count.index]
  subnet_id         = module.network[0].vnet_subnets[0]
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_ssh_cidrs = concat([format("%s/32", module.mx[0].private_ip)], module.network[0].vnet_address_space)

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
