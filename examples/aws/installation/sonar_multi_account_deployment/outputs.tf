output "dsf_agentless_gw" {
  value = {
    for idx, val in module.agentless_gw_main : "gw-${idx}" => {
      main = {
        private_ip   = try(val.private_ip, null)
        private_dns  = try(val.private_dns, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.gw_main_private_key_file_path} ${module.agentless_gw_main[idx].ssh_user}@${module.agentless_gw_main[idx].private_ip}", null)
      }
      dr = {
        private_ip   = try(val.private_ip, null)
        private_dns  = try(val.private_dns, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.gw_dr_private_key_file_path} ${module.agentless_gw_dr[idx].ssh_user}@${module.agentless_gw_dr[idx].private_ip}", null)
      }
    }
  }
}

output "dsf_hubs" {
  value = {
    main = {
      private_ip   = try(module.hub_main.private_ip, null)
      jsonar_uid   = try(module.hub_main.jsonar_uid, null)
      display_name = try(module.hub_main.display_name, null)
      ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.hub_main_private_key_file_path} ${module.hub_main.ssh_user}@${module.hub_main.private_ip}", null)
    }
    dr = {
      private_ip   = try(module.hub_dr.private_ip, null)
      jsonar_uid   = try(module.hub_dr.jsonar_uid, null)
      display_name = try(module.hub_dr.display_name, null)
      ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.hub_dr_private_key_file_path} ${module.hub_dr.ssh_user}@${module.hub_dr.private_ip}", null)
    }
  }
}

output "web_console_dsf_hub" {
  value = {
    private_url    = try(join("", ["https://", module.hub_main.private_ip, ":8443/"]), null)
    admin_password = var.password_secret_name != null ? "See the secret named '${var.password_secret_name}' in your AWS Secrets Manager" : nonsensitive(local.password)
  }
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_hub_main_ssh_key_file_path" {
  value = local.hub_main_private_key_file_path
}

output "dsf_hub_dr_ssh_key_file_path" {
  value = local.hub_dr_private_key_file_path
}

output "agentless_gw_main_ssh_key_file_path" {
  value = local.gw_main_private_key_file_path
}

output "agentless_gw_dr_ssh_key_file_path" {
  value = local.gw_dr_private_key_file_path
}
