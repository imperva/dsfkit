output "dsf_deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_private_ssh_key" {
  sensitive = true
  value     = try(module.key_pair.private_key_content, null)
}

output "dsf_private_ssh_key_file_path" {
  value = local.private_key_file_path
}

output "generated_network" {
  value = try({
    vpc             = module.vpc[0].vpc_id
    public_subnets  = module.vpc[0].public_subnets
    private_subnets = module.vpc[0].private_subnets
  }, null)
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
      ssh_command  = try("ssh -i ${local.private_key_file_path} ${module.hub_main[0].ssh_user}@${module.hub_main[0].public_dns}", null)
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
      ssh_command  = try("ssh -i ${local.private_key_file_path} ${module.hub_dr[0].ssh_user}@${module.hub_dr[0].public_dns}", null)
    } : null
    agentless_gw_main = [
      for idx, val in module.agentless_gw_main :
      {
        private_ip   = try(val.private_ip, null)
        private_dns  = try(val.private_dns, null)
        jsonar_uid   = try(val.jsonar_uid, null)
        display_name = try(val.display_name, null)
        role_arn     = try(val.iam_role, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.hub_main[0].ssh_user}@${module.hub_main[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
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
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.hub_main[0].ssh_user}@${module.hub_main[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ] : []
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
      ssh_command      = try("ssh -i ${local.private_key_file_path} ${module.mx[0].ssh_user}@${module.mx[0].public_dns}", null)
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
        ssh_command      = try("ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.mx[0].ssh_user}@${module.mx[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
        large_scale_mode = val.large_scale_mode
      }
    ]
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
      ssh_command  = try("ssh -i ${local.private_key_file_path} ${module.dra_admin[0].ssh_user}@${module.dra_admin[0].public_dns}", null)
    }
    analytics = [
      for idx, val in module.dra_analytics : {
        private_ip    = val.private_ip
        private_dns   = val.private_dns
        archiver_user = val.archiver_user
        ssh_command   = try("ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.dra_admin[0].ssh_user}@${module.dra_admin[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
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
        private_dns = val.private_dns
        db_type     = val.db_type
        os_type     = val.os_type
        ssh_command = try("ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local.private_key_file_path} -W %h:%p ${module.mx[0].ssh_user}@${module.mx[0].public_ip}' -i ${local.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
      }
    ]
    agentless_sources = var.enable_sonar ? {
      rds_mysql    = try(module.rds_mysql[0], null)
      rds_postgres = try(module.rds_postgres[0], null)
      rds_mssql    = try(module.rds_mssql[0], null)
    } : null
  }
}

output "web_console_dsf_hub" {
  value = try({
    user        = module.hub_main[0].web_console_user
    password    = nonsensitive(local.password)
    public_url  = join("", ["https://", module.hub_main[0].public_dns, ":8443/"])
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