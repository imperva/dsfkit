locals {
  cte_ddc_linux_count   = local.ciphertrust_manager_count > 0 ? var.cte_ddc_agents_linux_count : 0
  cte_linux_count       = local.ciphertrust_manager_count > 0 ? var.cte_agents_linux_count : 0
  ddc_linux_count       = local.ciphertrust_manager_count > 0 ? var.ddc_agents_linux_count : 0
  cte_ddc_windows_count = local.ciphertrust_manager_count > 0 ? var.cte_ddc_agents_windows_count : 0
  cte_windows_count     = local.ciphertrust_manager_count > 0 ? var.cte_agents_windows_count : 0
  ddc_windows_count     = local.ciphertrust_manager_count > 0 ? var.ddc_agents_windows_count : 0

  installation_map = {
    "Red Hat" = {
      cte_installation_path = var.cte_agent_linux_installation_file
      ddc_installation_path = var.ddc_agent_linux_installation_file
    },
    "Windows" = {
      cte_installation_path = var.cte_agent_windows_installation_file
      ddc_installation_path = var.ddc_agent_windows_installation_file
    }
  }

  # Prepare Linux Agent Instances
  linux_cte_ddc_instances = [for i in range(local.cte_ddc_linux_count) : {
    id          = "cte-ddc-agent-linux-${i}"
    os_type     = "Red Hat"
    install_cte = true
    install_ddc = true
  }]
  linux_cte_only_instances = [for i in range(local.cte_linux_count) : {
    id          = "cte-agent-linux-${i}"
    os_type     = "Red Hat"
    install_cte = true
    install_ddc = false
  }]
  linux_ddc_only_instances = [for i in range(local.ddc_linux_count) : {
    id          = "ddc-agent-linux-${i}"
    os_type     = "Red Hat"
    install_cte = false
    install_ddc = true
  }]
  # Prepare Windows Agent Instances
  windows_cte_ddc_instances = [for i in range(local.cte_ddc_windows_count) : {
    id          = "cte-ddc-agent-windows-${i}"
    os_type     = "Windows"
    install_cte = true
    install_ddc = true
  }]
  windows_cte_only_instances = [for i in range(local.cte_windows_count) : {
    id          = "cte-agent-windows-${i}"
    os_type     = "Windows"
    install_cte = true
    install_ddc = false
  }]
  windows_ddc_only_instances = [for i in range(local.ddc_windows_count) : {
    id          = "ddc-agent-windows-${i}"
    os_type     = "Windows"
    install_cte = false
    install_ddc = true
  }]


  # Concatenate all agent lists and convert to a map for for_each
  all_agent_instances_map = {
    for instance in concat(
      local.linux_cte_ddc_instances,
      local.linux_cte_only_instances,
      local.linux_ddc_only_instances,
      local.windows_cte_ddc_instances,
      local.windows_cte_only_instances,
      local.windows_ddc_only_instances
    ) : instance.id => instance
  }
}

resource "ciphertrust_cte_registration_token" "reg_token" {
  count = length(local.all_agent_instances_map) > 0 ? 1 : 0
  # give enough time for adding agents post initial deployment
  lifetime    = "90d"
  max_clients = 100
  name_prefix = "dsf-agent"

  depends_on = [
    module.ciphertrust_manager
  ]
}

module "cte_ddc_agents" {
  source        = "imperva/dsf-cte-ddc-agent/aws"
  version       = "1.7.32" # latest release tag
  for_each      = local.all_agent_instances_map
  friendly_name = join("-", [local.deployment_name_salted, each.value.id])
  ebs           = var.cte_ddc_agent_ebs_details
  subnet_id     = local.cte_ddc_agent_subnet_id
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  os_type                      = each.value.os_type
  attach_persistent_public_ip  = true
  use_public_ip                = true
  allowed_ssh_cidrs            = concat(local.workstation_cidr, var.allowed_ssh_cidrs)
  allowed_rdp_cidrs            = each.value.os_type == "Windows" ? concat(local.workstation_cidr, var.allowed_ssh_cidrs) : []
  cipher_trust_manager_address = module.ciphertrust_manager[0].private_ip
  agent_installation = {
    registration_token          = ciphertrust_cte_registration_token.reg_token[0].token
    install_cte                 = each.value.install_cte
    install_ddc                 = each.value.install_ddc
    cte_agent_installation_file = each.value.install_cte ? local.installation_map[each.value.os_type].cte_installation_path : null
    ddc_agent_installation_file = each.value.install_ddc ? local.installation_map[each.value.os_type].ddc_installation_path : null
  }
  tags = local.tags
  depends_on = [
    module.vpc,
    module.ciphertrust_manager,
    ciphertrust_trial_license.trial_license,
    module.ciphertrust_manager_cluster_setup
  ]
}


