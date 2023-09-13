output "dsf_agentless_gw" {
  value = {
    for idx, val in module.agentless_gw : "agentless-gw-${idx}" => {
      main = {
        private_ip   = try(val.private_ip, null)
        private_dns  = try(val.private_dns, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.hub_private_key_file_path} -W %h:%p ${module.hub_main.ssh_user}@${module.hub_main.private_ip}' -i ${local.gw_private_key_file_path} ${module.agentless_gw[idx].ssh_user}@${module.agentless_gw[idx].private_ip}", null)
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
      ssh_command  = try("ssh -i ${local.hub_private_key_file_path} ${module.hub_main.ssh_user}@${module.hub_main.private_ip}", null)
    }
    dr = {
      private_ip   = try(module.hub_dr.private_ip, null)
      jsonar_uid   = try(module.hub_dr.jsonar_uid, null)
      display_name = try(module.hub_dr.display_name, null)
      ssh_command  = try("ssh -i ${local.hub_private_key_file_path} ${module.hub_dr.ssh_user}@${module.hub_dr.private_ip}", null)
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

output "dsf_hub_ssh_key_file_path" {
  value = local.hub_private_key_file_path
}

output "dsf_gws_ssh_key_file_path" {
  value = local.gw_private_key_file_path
}
