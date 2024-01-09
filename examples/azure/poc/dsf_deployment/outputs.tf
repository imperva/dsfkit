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
    hub_main = {
      public_ip    = try(module.hub_main[0].public_ip, null)
      private_ip   = try(module.hub_main[0].private_ip, null)
      jsonar_uid   = try(module.hub_main[0].jsonar_uid, null)
      display_name = try(module.hub_main[0].display_name, null)
      principal_id = try(module.hub_main[0].principal_id, null)
      ssh_command  = try("ssh -i ${local.private_key_file_path} ${module.hub_main[0].ssh_user}@${module.hub_main[0].public_ip}", null)
      tokens       = nonsensitive(module.hub_main[0].access_tokens)
    }
    hub_dr = var.hub_hadr ? {
      public_ip    = try(module.hub_dr[0].public_ip, null)
      private_ip   = try(module.hub_dr[0].private_ip, null)
      jsonar_uid   = try(module.hub_dr[0].jsonar_uid, null)
      display_name = try(module.hub_dr[0].display_name, null)
      principal_id = try(module.hub_dr[0].principal_id, null)
      ssh_command  = try("ssh -i ${local.private_key_file_path} ${module.hub_dr[0].ssh_user}@${module.hub_dr[0].public_ip}", null)
    } : null
    agentless_gw_main = [
      for idx, val in module.agentless_gw_main :
      {
        private_ip   = try(val.private_ip, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        principal_id = try(val.principal_id, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.hub_main[0].ssh_user}@${module.hub_main[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ]
    agentless_gw_dr = var.agentless_gw_hadr ? [
      for idx, val in module.agentless_gw_dr :
      {
        private_ip   = try(val.private_ip, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        principal_id = try(val.principal_id, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.hub_main[0].ssh_user}@${module.hub_main[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ] : []
  } : null
}

output "dam" {
  value = var.enable_dam ? {
    mx = {
      public_ip        = try(module.mx[0].public_ip, null)
      private_ip       = try(module.mx[0].private_ip, null)
      display_name     = try(module.mx[0].display_name, null)
      ssh_command      = try("ssh -i ${local.private_key_file_path} ${module.mx[0].ssh_user}@${module.mx[0].public_ip}", null)
      public_url       = try(join("", ["https://", module.mx[0].public_ip, ":8083/"]), null)
      private_url      = try(join("", ["https://", module.mx[0].private_ip, ":8083/"]), null)
      password         = nonsensitive(local.password)
      user             = module.mx[0].web_console_user
      large_scale_mode = module.mx[0].large_scale_mode
    }
    agent_gw = [
      for idx, val in module.agent_gw : {
        private_ip       = try(val.private_ip, null)
        public_ip        = try(val.public_ip, null)
        display_name     = try(val.display_name, null)
        ssh_command      = try("ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.mx[0].ssh_user}@${module.mx[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
        large_scale_mode = val.large_scale_mode
      }
    ]
  } : null
}

output "audit_sources" {
  value = {
    agent_sources = [
      for idx, val in module.db_with_agent :
      {
        private_ip  = val.private_ip
        db_type     = val.db_type
        os_type     = val.os_type
        ssh_command = try("ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.mx[0].ssh_user}@${module.mx[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ]
  }
}

output "web_console_dsf_hub" {
  value = try({
    user        = module.hub_main[0].web_console_user
    password    = nonsensitive(local.password)
    public_url  = join("", ["https://", module.hub_main[0].public_ip, ":8443/"])
    private_url = join("", ["https://", module.hub_main[0].private_ip, ":8443/"])
  }, null)
}