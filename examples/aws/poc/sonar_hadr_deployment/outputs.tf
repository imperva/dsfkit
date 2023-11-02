output "dsf_agentless_gw" {
  value = {
    for idx, val in module.agentless_gw_main : "agentless-gw-${idx}" => {
      main = {
        private_ip   = try(module.agentless_gw_main[idx].private_ip, null)
        private_dns  = try(module.agentless_gw_main[idx].private_dns, null)
        jsonar_uid   = try(module.agentless_gw_main[idx].jsonar_uid, null)
        display_name = try(module.agentless_gw_main[idx].display_name, null)
        role_arn     = try(module.agentless_gw_main[idx].iam_role, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.private_key_file_path} -W %h:%p ${module.hub_main.ssh_user}@${module.hub_main.public_ip}' -i ${module.key_pair.private_key_file_path} ${module.agentless_gw_main[idx].ssh_user}@${module.agentless_gw_main[idx].private_ip}", null)
      }
      dr = {
        private_ip   = try(module.agentless_gw_dr[idx].private_ip, null)
        private_dns  = try(module.agentless_gw_dr[idx].private_dns, null)
        jsonar_uid   = try(module.agentless_gw_dr[idx].jsonar_uid, null)
        display_name = try(module.agentless_gw_dr[idx].display_name, null)
        role_arn     = try(module.agentless_gw_dr[idx].iam_role, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.private_key_file_path} -W %h:%p ${module.hub_main.ssh_user}@${module.hub_main.public_ip}' -i ${module.key_pair.private_key_file_path} ${module.agentless_gw_dr[idx].ssh_user}@${module.agentless_gw_dr[idx].private_ip}", null)
      }
    }
  }
}

output "dsf_hubs" {
  value = {
    main = {
      public_ip    = try(module.hub_main.public_ip, null)
      public_dns   = try(module.hub_main.public_dns, null)
      private_ip   = try(module.hub_main.private_ip, null)
      private_dns  = try(module.hub_main.private_dns, null)
      jsonar_uid   = try(module.hub_main.jsonar_uid, null)
      display_name = try(module.hub_main.display_name, null)
      role_arn     = try(module.hub_main.iam_role, null)
      ssh_command  = try("ssh -i ${module.key_pair.private_key_file_path} ${module.hub_main.ssh_user}@${module.hub_main.public_dns}", null)
    }
    dr = {
      public_ip    = try(module.hub_dr.public_ip, null)
      public_dns   = try(module.hub_dr.public_dns, null)
      private_ip   = try(module.hub_dr.private_ip, null)
      private_dns  = try(module.hub_dr.private_dns, null)
      jsonar_uid   = try(module.hub_dr.jsonar_uid, null)
      display_name = try(module.hub_dr.display_name, null)
      role_arn     = try(module.hub_dr.iam_role, null)
      ssh_command  = try("ssh -i ${module.key_pair.private_key_file_path} ${module.hub_dr.ssh_user}@${module.hub_dr.public_dns}", null)
    }
  }
}

output "web_console_dsf_hub" {
  value = {
    public_url     = try(join("", ["https://", module.hub_main.public_dns, ":8443/"]), null)
    private_url    = try(join("", ["https://", module.hub_main.private_dns, ":8443/"]), null)
    admin_password = nonsensitive(local.password)
  }
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_private_ssh_key" {
  sensitive = true
  value     = try(module.key_pair.private_key_content, null)
}

output "dsf_private_ssh_key_file_path" {
  value = module.key_pair.private_key_file_path
}

output "mysql_db_details" {
  value = try(module.rds_mysql, null)
}

output "mssql_db_details" {
  value = try(module.rds_mssql, null)
}