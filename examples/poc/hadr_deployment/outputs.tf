output "dsf_agentless_gw_group" {
  value = {
    for idx, val in module.agentless_gw_group_primary : "agentless-gw-${idx}" => {
      primary = {
        private_ip   = try(module.agentless_gw_group_primary[idx].private_ip, null)
        private_dns  = try(module.agentless_gw_group_primary[idx].private_dns, null)
        jsonar_uid   = try(module.agentless_gw_group_primary[idx].jsonar_uid, null)
        display_name = try(module.agentless_gw_group_primary[idx].display_name, null)
        role_arn     = try(module.agentless_gw_group_primary[idx].iam_role, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.private_key_file_path} -W %h:%p ${module.hub_primary.ssh_user}@${module.hub_primary.public_ip}' -i ${module.key_pair.private_key_file_path} ${module.agentless_gw_group_primary[idx].ssh_user}@${module.agentless_gw_group_primary[idx].private_ip}", null)
      }
      secondary = {
        private_ip   = try(module.agentless_gw_group_secondary[idx].private_ip, null)
        private_dns  = try(module.agentless_gw_group_secondary[idx].private_dns, null)
        jsonar_uid   = try(module.agentless_gw_group_secondary[idx].jsonar_uid, null)
        display_name = try(module.agentless_gw_group_secondary[idx].display_name, null)
        role_arn     = try(module.agentless_gw_group_secondary[idx].iam_role, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.private_key_file_path} -W %h:%p ${module.hub_primary.ssh_user}@${module.hub_primary.public_ip}' -i ${module.key_pair.private_key_file_path} ${module.agentless_gw_group_secondary[idx].ssh_user}@${module.agentless_gw_group_secondary[idx].private_ip}", null)
      }
    }
  }
}

output "dsf_hubs" {
  value = {
    primary = {
      public_ip    = try(module.hub_primary.public_ip, null)
      public_dns   = try(module.hub_primary.public_dns, null)
      private_ip   = try(module.hub_primary.private_ip, null)
      private_dns  = try(module.hub_primary.private_dns, null)
      jsonar_uid   = try(module.hub_primary.jsonar_uid, null)
      display_name = try(module.hub_primary.display_name, null)
      role_arn     = try(module.hub_primary.iam_role, null)
      ssh_command  = try("ssh -i ${module.key_pair.private_key_file_path} ${module.hub_primary.ssh_user}@${module.hub_primary.public_dns}", null)
    }
    secondary = {
      public_ip    = try(module.hub_secondary.public_ip, null)
      public_dns   = try(module.hub_secondary.public_dns, null)
      private_ip   = try(module.hub_secondary.private_ip, null)
      private_dns  = try(module.hub_secondary.private_dns, null)
      jsonar_uid   = try(module.hub_secondary.jsonar_uid, null)
      display_name = try(module.hub_secondary.display_name, null)
      role_arn     = try(module.hub_secondary.iam_role, null)
      ssh_command  = try("ssh -i ${module.key_pair.private_key_file_path} ${module.hub_secondary.ssh_user}@${module.hub_secondary.public_dns}", null)
    }
  }
}

output "web_console_dsf_hub" {
  value = {
    public_url     = try(join("", ["https://", module.hub_primary.public_dns, ":8443/"]), null)
    private_url    = try(join("", ["https://", module.hub_primary.private_dns, ":8443/"]), null)
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

output "dsf_private_ssh_key_file_path" {
  value = module.key_pair.private_key_file_path
}

output "mysql_db_details" {
  value = try(module.rds_mysql, null)
}

output "mssql_db_details" {
  value = try(module.rds_mssql, null)
}