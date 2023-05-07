output "dsf_agentless_gw_group" {
  value = {
    for idx, val in module.agentless_gw_group : "agentless-gw-${idx}" =>
    {
      private_ip   = try(val.private_ip, null)
      jsonar_uid   = try(val.jsonar_uid, null)
      display_name = try(val.display_name, null)
      role_arn     = try(val.iam_role, null)
      ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.hub_private_key_pem_file_path} -W %h:%p ${module.hub.ssh_user}@${module.hub.private_ip}' -i ${local.gw_private_key_pem_file_path} ${val.ssh_user}@${val.private_ip}", null)
    }
  }
}

output "dsf_hubs" {
  value = {
    primary_hub = {
      private_ip   = try(module.hub.private_ip, null)
      jsonar_uid   = try(module.hub.jsonar_uid, null)
      display_name = try(module.hub.display_name, null)
      role_arn     = try(module.hub.iam_role, null)
      ssh_command  = try("ssh -i ${local.hub_private_key_pem_file_path} ${module.hub.ssh_user}@${module.hub.private_ip}", null)
    }
  }
}

output "dsf_hub_web_console" {
  value = {
    private_url    = try(join("", ["https://", module.hub.private_ip, ":8443/"]), null)
    admin_password = nonsensitive(local.web_console_admin_password)
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
