output "dsf_deployment_name" {
  value = local.deployment_name_salted
}

output "sonar" {
  value = var.enable_sonar ? {
    hub_main = {
      public_ip    = try(module.hub_main[0].public_ip, null)
      public_dns   = try(module.hub_main[0].public_dns, null)
      private_ip   = try(module.hub_main[0].private_ip, null)
      private_dns  = try(module.hub_main[0].private_dns, null)
      jsonar_uid   = try(module.hub_main[0].jsonar_uid, null)
      display_name = try(module.hub_main[0].display_name, null)
      role_arn     = try(module.hub_main[0].iam_role, null)
      ssh_command  = var.proxy_address == null ? try("ssh -i ${local.hub_main_private_key_file_path} ${module.hub_main[0].ssh_user}@${local.hub_main_ip}", null) : try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.hub_main_private_key_file_path} ${module.hub_main[0].ssh_user}@${module.hub_main[0].private_dns}", null)
      tokens       = nonsensitive(module.hub_main[0].access_tokens)
    }
    hub_dr = var.hub_hadr ? {
      public_ip    = try(module.hub_dr[0].public_ip, null)
      public_dns   = try(module.hub_dr[0].public_dns, null)
      private_ip   = try(module.hub_dr[0].private_ip, null)
      private_dns  = try(module.hub_dr[0].private_dns, null)
      jsonar_uid   = try(module.hub_dr[0].jsonar_uid, null)
      display_name = try(module.hub_dr[0].display_name, null)
      role_arn     = try(module.hub_dr[0].iam_role, null)
      ssh_command  = var.proxy_address == null ? try("ssh -i ${local.hub_dr_private_key_file_path} ${module.hub_dr[0].ssh_user}@${local.hub_dr_ip}", null) : try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.hub_dr_private_key_file_path} ${module.hub_dr[0].ssh_user}@${module.hub_dr[0].private_dns}", null)
    } : null
    agentless_gw_main = [
      for idx, val in module.agentless_gw_main :
      {
        private_ip   = try(val.private_ip, null)
        private_dns  = try(val.private_dns, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        role_arn     = try(val.iam_role, null)
        ssh_command  = var.proxy_address == null ? try("ssh -i ${local.agentless_gw_main_private_key_file_path} ${val.ssh_user}@${val.private_ip}", null) : try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.agentless_gw_main_private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ]
    agentless_gw_dr = var.agentless_gw_hadr ? [
      for idx, val in module.agentless_gw_dr :
      {
        private_ip   = try(val.private_ip, null)
        private_dns  = try(val.private_dns, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        role_arn     = try(val.iam_role, null)
        ssh_command  = var.proxy_address == null ? try("ssh -i ${local.agentless_gw_dr_private_key_file_path} ${val.ssh_user}@${val.private_ip}", null) : try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.agentless_gw_dr_private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ] : []
    dsf_hub_main_ssh_key_file_path      = local.hub_main_private_key_file_path
    dsf_hub_dr_ssh_key_file_path        = local.hub_dr_private_key_file_path
    agentless_gw_main_ssh_key_file_path = local.agentless_gw_main_private_key_file_path
    agentless_gw_dr_ssh_key_file_path   = local.agentless_gw_dr_private_key_file_path
  } : null
}

output "dam" {
  value = var.enable_dam ? {
    mx = {
      public_ip        = try(module.mx[0].public_ip, null)
      public_dns       = try(module.mx[0].public_dns, null)
      private_ip       = try(module.mx[0].private_ip, null)
      private_dns      = try(module.mx[0].private_dns, null)
      display_name     = try(module.mx[0].display_name, null)
      role_arn         = try(module.mx[0].iam_role, null)
      ssh_command      = try("ssh -i ${local.mx_private_key_file_path} ${module.mx[0].ssh_user}@${module.mx[0].public_dns}", null)
      public_url       = try(join("", ["https://", module.mx[0].public_dns, ":8083/"]), null)
      private_url      = try(join("", ["https://", module.mx[0].private_dns, ":8083/"]), null)
      password         = nonsensitive(local.password)
      user             = module.mx[0].web_console_user
      large_scale_mode = module.mx[0].large_scale_mode
    }
    agent_gw = [
      for idx, val in module.agent_gw : {
        private_ip       = try(val.private_ip, null)
        private_dns      = try(val.private_dns, null)
        public_ip        = try(val.public_ip, null)
        public_dns       = try(val.public_dns, null)
        display_name     = try(val.display_name, null)
        role_arn         = try(val.iam_role, null)
        group_id         = try(val.group_id, null)
        ssh_command      = var.proxy_address == null ? try("ssh -i ${local.agent_gw_private_key_file_path} ${val.ssh_user}@${val.private_ip}", null) : try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.agent_gw_private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
        large_scale_mode = val.large_scale_mode
      }
    ]
    mx_ssh_key_file_path       = local.mx_private_key_file_path
    agent_gw_ssh_key_file_path = local.agent_gw_private_key_file_path
  } : null
}

output "dra" {
  value = var.enable_dra ? {
    admin_server = {
      public_ip    = try(module.dra_admin[0].public_ip, null)
      public_dns   = try(module.dra_admin[0].public_dns, null)
      private_ip   = try(module.dra_admin[0].private_ip, null)
      private_dns  = try(module.dra_admin[0].private_dns, null)
      display_name = try(module.dra_admin[0].display_name, null)
      role_arn     = try(module.dra_admin[0].iam_role, null)
      ssh_command  = try("ssh -i ${local.dra_admin_private_key_file_path} ${module.dra_admin[0].ssh_user}@${module.dra_admin[0].public_dns}", null)
    }
    analytics = [
      for idx, val in module.dra_analytics : {
        private_ip    = val.private_ip
        private_dns   = val.private_dns
        archiver_user = val.archiver_user
        role_arn      = val.iam_role
        ssh_command   = var.proxy_address == null ? try("ssh -i ${local.dra_analytics_private_key_file_path} ${val.ssh_user}@${val.private_ip}", null) : try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${var.proxy_ssh_key_path} -W %h:%p ${var.proxy_ssh_user}@${var.proxy_address}' -i ${local.dra_analytics_private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ]
    dra_admin_ssh_key_file_path     = local.dra_admin_private_key_file_path
    dra_analytics_ssh_key_file_path = local.dra_analytics_private_key_file_path
  } : null
}

output "web_console_dsf_hub" {
  value = try({
    user        = module.hub_main[0].web_console_user
    password    = nonsensitive(local.password)
    public_url  = length(module.hub_main[0].public_dns) > 0 ? join("", ["https://", module.hub_main[0].public_dns, ":8443/"]) : null
    private_url = join("", ["https://", module.hub_main[0].private_dns, ":8443/"])
  }, null)
}

output "web_console_dra" {
  value = try({
    public_url  = join("", ["https://", module.dra_admin[0].public_dns, ":8443/"])
    private_url = join("", ["https://", module.dra_admin[0].private_dns, ":8443/"])
  }, null)
}

output "web_console_dam" {
  value = try({
    public_url  = join("", ["https://", module.mx[0].public_dns, ":8083/"])
    private_url = join("", ["https://", module.mx[0].private_dns, ":8083/"])
    password    = nonsensitive(local.password)
    user        = module.mx[0].web_console_user
  }, null)
}

