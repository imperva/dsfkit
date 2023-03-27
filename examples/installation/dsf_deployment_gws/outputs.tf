output "dsf_agentless_gw1_group" {
  value = {
    for idx, val in module.agentless_gw1_group : "gw1-${idx}" => {
      primary = {
        private_ip   = try(module.agentless_gw1_group[idx].private_ip, null)
        private_dns  = try(module.agentless_gw1_group[idx].private_dns, null)
        jsonar_uid   = try(module.agentless_gw1_group[idx].jsonar_uid, null)
        display_name = try(module.agentless_gw1_group[idx].display_name, null)
        role_arn     = try(module.agentless_gw1_group[idx].iam_role, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.hub_private_key_pem_file_path} -W %h:%p ${var.hub_ssh_user}@${var.hub_private_ip}' -i ${module.key_pair_gw1.private_key_file_path} ${module.agentless_gw1_group[idx].ssh_user}@${module.agentless_gw1_group[idx].private_ip}", null)
      }
    }
  }
}

output "dsf_agentless_gw2_group" {
  value = {
    for idx, val in module.agentless_gw2_group : "gw2-${idx}" => {
      primary = {
        private_ip   = try(module.agentless_gw2_group[idx].private_ip, null)
        private_dns  = try(module.agentless_gw2_group[idx].private_dns, null)
        jsonar_uid   = try(module.agentless_gw2_group[idx].jsonar_uid, null)
        display_name = try(module.agentless_gw2_group[idx].display_name, null)
        role_arn     = try(module.agentless_gw2_group[idx].iam_role, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.hub_private_key_pem_file_path} -W %h:%p ${var.hub_ssh_user}@${var.hub_private_ip}' -i ${module.key_pair_gw2.private_key_file_path} ${module.agentless_gw2_group[idx].ssh_user}@${module.agentless_gw2_group[idx].private_ip}", null)
      }
    }
  }
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_gw1_ssh_key" {
  sensitive = true
  value     = module.key_pair_gw1.key_pair_private_pem
}

output "dsf_gw2_ssh_key" {
  sensitive = true
  value     = module.key_pair_gw2.key_pair_private_pem
}
