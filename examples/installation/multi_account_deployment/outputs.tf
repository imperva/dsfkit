output "dsf_agentless_gw_group" {
  value = {
  for idx, val in module.agentless_gw_group_primary : "gw-${idx}" => {
    primary = {
      private_ip   = try(module.agentless_gw_group_primary[idx].private_ip, null)
      private_dns  = try(module.agentless_gw_group_primary[idx].private_dns, null)
      jsonar_uid   = try(module.agentless_gw_group_primary[idx].jsonar_uid, null)
      display_name = try(module.agentless_gw_group_primary[idx].display_name, null)
      role_arn     = try(module.agentless_gw_group_primary[idx].iam_role, null)
      ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair_hub.private_key_file_path} -W %h:%p ${module.hub_primary.ssh_user}@${module.hub_primary.private_ip}' -i ${module.key_pair_gw.private_key_file_path} ${module.agentless_gw_group_primary[idx].ssh_user}@${module.agentless_gw_group_primary[idx].private_ip}", null)
    }
    secondary = {
      private_ip   = try(module.agentless_gw_group_secondary[idx].private_ip, null)
      private_dns  = try(module.agentless_gw_group_secondary[idx].private_dns, null)
      jsonar_uid   = try(module.agentless_gw_group_secondary[idx].jsonar_uid, null)
      display_name = try(module.agentless_gw_group_secondary[idx].display_name, null)
      role_arn     = try(module.agentless_gw_group_secondary[idx].iam_role, null)
      ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair_hub.private_key_file_path} -W %h:%p ${module.hub_primary.ssh_user}@${module.hub_primary.private_ip}' -i ${module.key_pair_gw_secondary.private_key_file_path} ${module.agentless_gw_group_secondary[idx].ssh_user}@${module.agentless_gw_group_secondary[idx].private_ip}", null)
    }
  }
  }
}

output "dsf_hubs" {
  value = {
    primary = {
      private_ip   = try(module.hub_primary.private_ip, null)
      jsonar_uid   = try(module.hub_primary.jsonar_uid, null)
      display_name = try(module.hub_primary.display_name, null)
      role_arn     = try(module.hub_primary.iam_role, null)
      ssh_command  = try("ssh -i ${module.key_pair_hub.private_key_file_path} ${module.hub_primary.ssh_user}@${module.hub_primary.private_ip}", null)
    }
    secondary = {
      private_ip   = try(module.hub_secondary.private_ip, null)
      jsonar_uid   = try(module.hub_secondary.jsonar_uid, null)
      display_name = try(module.hub_secondary.display_name, null)
      role_arn     = try(module.hub_secondary.iam_role, null)
      ssh_command  = try("ssh -i ${module.key_pair_hub_secondary.private_key_file_path} ${module.hub_secondary.ssh_user}@${module.hub_secondary.private_ip}", null)
    }
  }
}

output "dsf_hub_web_console" {
  value = {
    private_url    = try(join("", ["https://", module.hub_primary.private_ip, ":8443/"]), null)
    admin_password = nonsensitive(local.web_console_admin_password)
  }
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_hub_ssh_key" {
  sensitive = true
  value     = module.key_pair_hub.key_pair_private_pem
}

output "dsf_hub_secondary_ssh_key" {
  sensitive = true
  value     = module.key_pair_hub_secondary.key_pair_private_pem
}

output "dsf_gw_ssh_key" {
  sensitive = true
  value     = module.key_pair_gw.key_pair_private_pem
}

output "dsf_gw_secondary_ssh_key" {
  sensitive = true
  value     = module.key_pair_gw_secondary.key_pair_private_pem
}