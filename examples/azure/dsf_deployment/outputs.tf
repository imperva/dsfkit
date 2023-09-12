output "dsf_deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_private_ssh_key" {
  sensitive = true
  value     = try(tls_private_key.ssh_key.private_key_openssh, null)
}

output "dsf_private_ssh_key_file_path" {
  value = local_sensitive_file.ssh_key.filename
}

output "generated_network" {
  value = try({
    vnet    = module.network[0].vnet_id
    subnets = module.network[0].vnet_subnets
  }, null)
}

output "sonar" {
  value = var.enable_sonar ? {
    hub = {
      public_ip    = try(module.hub[0].public_ip, null)
      private_ip   = try(module.hub[0].private_ip, null)
      jsonar_uid   = try(module.hub[0].jsonar_uid, null)
      display_name = try(module.hub[0].display_name, null)
      principal_id = try(module.hub[0].principal_id, null)
      ssh_command  = try("ssh -i ${local.private_key_file_path} ${module.hub[0].ssh_user}@${module.hub[0].public_ip}", null)
      tokens       = nonsensitive(module.hub[0].access_tokens)
    }
    hub_secondary = var.hub_hadr ? {
      public_ip    = try(module.hub_secondary[0].public_ip, null)
      private_ip   = try(module.hub_secondary[0].private_ip, null)
      jsonar_uid   = try(module.hub_secondary[0].jsonar_uid, null)
      display_name = try(module.hub_secondary[0].display_name, null)
      principal_id = try(module.hub_secondary[0].principal_id, null)
      ssh_command  = try("ssh -i ${local.private_key_file_path} ${module.hub_secondary[0].ssh_user}@${module.hub_secondary[0].public_ip}", null)
    } : null
    agentless_gw = [
      for idx, val in module.agentless_gw :
      {
        private_ip   = try(val.private_ip, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        principal_id = try(val.principal_id, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.hub[0].ssh_user}@${module.hub[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ]
    agentless_gw_secondary = var.agentless_gw_hadr ? [
      for idx, val in module.agentless_gw_secondary :
      {
        private_ip   = try(val.private_ip, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        principal_id     = try(val.principal_id, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.hub[0].ssh_user}@${module.hub[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ] : []
  } : null
}

output "web_console_dsf_hub" {
  value = try({
    user        = module.hub[0].web_console_user
    password    = nonsensitive(local.password)
    public_url  = join("", ["https://", module.hub[0].public_ip, ":8443/"])
    private_url = join("", ["https://", module.hub[0].private_ip, ":8443/"])
  }, null)
}
