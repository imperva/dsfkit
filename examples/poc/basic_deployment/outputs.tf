output "dsf_agentless_gw_group" {
  value = {
    for idx, val in module.agentless_gw_group : "gw-${idx}" =>
    {
      private_ip   = try(val.private_ip, null)
      private_dns  = try(val.private_dns, null)
      jsonar_uid   = try(val.jsonar_uid, null)
      display_name = try(val.display_name, null)
      role_arn     = try(val.iam_role, null)
      ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.key_pair_private_pem.filename} -W %h:%p ${module.hub.ssh_user}@${module.hub.public_ip}' -i ${module.key_pair.key_pair_private_pem.filename} ${val.ssh_user}@${val.private_ip}", null)
    }
  }
}

output "dsf_hub" {
  value = {
    public_ip    = try(module.hub.public_ip, null)
    public_dns   = try(module.hub.public_dns, null)
    private_ip   = try(module.hub.private_ip, null)
    private_dns  = try(module.hub.private_dns, null)
    jsonar_uid   = try(module.hub.jsonar_uid, null)
    display_name = try(module.hub.display_name, null)
    role_arn     = try(module.hub.iam_role, null)
    ssh_command  = try("ssh -i ${module.key_pair.key_pair_private_pem.filename} ${module.hub.ssh_user}@${module.hub.public_dns}", null)
  }
}

output "dsf_hub_web_console" {
  value = {
    public_url     = try(join("", ["https://", module.hub.public_dns, ":8443/"]), null)
    private_url    = try(join("", ["https://", module.hub.private_dns, ":8443/"]), null)
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
  value = try(module.key_pair.key_pair_private_pem.filename, null)
}

output "dsf_hub_web_console_url" {
  value = try(join("", ["https://", module.hub.public_dns, ":8443/"]), null)
}

output "mysql_db_details" {
  value = try(module.rds_mysql, null)
}

output "mssql_db_details" {
  value = try(module.rds_mssql, null)
}
