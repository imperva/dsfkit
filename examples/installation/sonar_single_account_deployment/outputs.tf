output "dsf_agentless_gw_group" {
  value = {
    for idx, val in module.agentless_gw_group : "agentless-gw-${idx}" => {
      primary = {
        private_ip   = try(val.private_ip, null)
        private_dns  = try(val.private_dns, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.hub_private_key_pem_file_path} -W %h:%p ${module.hub_primary.ssh_user}@${module.hub_primary.private_ip}' -i ${local.gw_private_key_pem_file_path} ${module.agentless_gw_group[idx].ssh_user}@${module.agentless_gw_group[idx].private_ip}", null)
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
      ssh_command  = try("ssh -i ${local.hub_private_key_pem_file_path} ${module.hub_primary.ssh_user}@${module.hub_primary.private_ip}", null)
    }
    secondary = {
      private_ip   = try(module.hub_secondary.private_ip, null)
      jsonar_uid   = try(module.hub_secondary.jsonar_uid, null)
      display_name = try(module.hub_secondary.display_name, null)
      ssh_command  = try("ssh -i ${local.hub_private_key_pem_file_path} ${module.hub_secondary.ssh_user}@${module.hub_secondary.private_ip}", null)
    }
  }
}

output "web_console_dsf_hub" {
  value = {
    private_url    = try(join("", ["https://", module.hub_primary.private_ip, ":8443/"]), null)
    admin_password = var.password_secret_name != null ? "See the secret named '${var.password_secret_name}' in your AWS Secrets Manager" : nonsensitive(local.password)
  }
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_hub_ssh_key_file_path" {
  value = local.hub_private_key_pem_file_path
}

output "dsf_gws_ssh_key_file_path" {
  value = local.gw_private_key_pem_file_path
}
