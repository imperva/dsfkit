output "dsf_agentless_gw_group" {
  value = {
    for idx, val in module.agentless_gw_group_primary : "gw-${idx}" => {
      primary = {
        private_ip   = try(val.private_ip, null)
        private_dns  = try(val.private_dns, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.gw_primary_private_key_pem_file_path} ${module.agentless_gw_group_primary[idx].ssh_user}@${module.agentless_gw_group_primary[idx].private_ip}", null)
      }
      secondary = {
        private_ip   = try(val.private_ip, null)
        private_dns  = try(val.private_dns, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.gw_secondary_private_key_pem_file_path} ${module.agentless_gw_group_secondary[idx].ssh_user}@${module.agentless_gw_group_secondary[idx].private_ip}", null)
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
      ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.hub_primary_private_key_pem_file_path} ${module.hub_primary.ssh_user}@${module.hub_primary.private_ip}", null)
    }
    secondary = {
      private_ip   = try(module.hub_secondary.private_ip, null)
      jsonar_uid   = try(module.hub_secondary.jsonar_uid, null)
      display_name = try(module.hub_secondary.display_name, null)
      ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.hub_secondary_private_key_pem_file_path} ${module.hub_secondary.ssh_user}@${module.hub_secondary.private_ip}", null)
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

output "dsf_hub_primary_ssh_key_file_path" {
  value = local.hub_primary_private_key_pem_file_path
}

output "dsf_hub_secondary_ssh_key_file_path" {
  value = local.hub_secondary_private_key_pem_file_path
}

output "dsf_gw_primary_ssh_key_file_path" {
  value = local.gw_primary_private_key_pem_file_path
}

output "dsf_gw_secondary_ssh_key_file_path" {
  value = local.gw_secondary_private_key_pem_file_path
}
