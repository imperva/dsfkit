output "dsf_agentless_gw_group" {
  value = {
    for idx, val in module.agentless_gw_group : "gw-${idx}" =>
    {
      private_address = try(val.private_address, null)
      jsonar_uid      = try(val.jsonar_uid, null)
      display_name    = try(val.display_name, null)
      role_arn        = try(val.iam_role, null)
      ssh_command     = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.key_pair_private_pem.filename} -W %h:%p ${module.hub.ssh_user}@${module.hub.public_address}' -i ${module.key_pair.key_pair_private_pem.filename} ${val.ssh_user}@${val.private_address}", null)
    }
  }
}

output "dsf_hubs" {
  value = {
    primary = {
      public_address  = try(module.hub.public_address, null)
      private_address = try(module.hub.private_address, null)
      jsonar_uid      = try(module.hub.jsonar_uid, null)
      display_name    = try(module.hub.display_name, null)
      role_arn        = try(module.hub.iam_role, null)
      ssh_command     = try("ssh -i ${module.key_pair.key_pair_private_pem.filename} ${module.hub.ssh_user}@${module.hub.public_address}", null)
    }
  }
}

output "dsf_hub_web_console" {
  value = {
    public_url = try(join("", ["https://", module.hub.public_address, ":8443/"]), null)
    private_url = try(join("", ["https://", module.hub.private_address, ":8443/"]), null)
    admin_password = nonsensitive(local.web_console_admin_password)
  }
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_private_ssh_key" {
  sensitive = true
  value     = try(module.key_pair.key_pair_private_pem, null)
}

output "dsf_private_ssh_key_file_name" {
  value     = try(module.key_pair.key_pair_private_pem.filename, null)
}

output "dsf_hub_web_console_url" {
  value = try(join("", ["https://", module.hub.public_address, ":8443/"]), null)
}
