output "dsf_agents" {
  value = {
    for idx, val in module.agent_monitored_db : "agent-${idx}" =>
    {
      private_ip  = val.private_ip
      private_dns = val.private_dns
      db_type     = val.db_type
      os_type     = val.os_type
      ssh_command = try("ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.private_key_file_path} -W %h:%p ${module.mx.ssh_user}@${module.mx.public_ip}' -i ${module.key_pair.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
    }
  }
}

output "dsf_agent_gw_group" {
  value = {
    for idx, val in module.agent_gw : "agent-gw-${idx}" =>
    {
      private_ip   = try(val.private_ip, null)
      private_dns  = try(val.private_dns, null)
      public_ip    = try(val.public_ip, null)
      public_dns   = try(val.public_dns, null)
      display_name = try(val.display_name, null)
      role_arn     = try(val.iam_role, null)
      group_id     = try(val.group_id, null)
      ssh_command  = try("ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.private_key_file_path} -W %h:%p ${module.mx.ssh_user}@${module.mx.public_ip}' -i ${module.key_pair.private_key_file_path} ${val.ssh_user}@${val.private_ip}", null)
    }
  }
}

output "dsf_mx" {
  value = {
    public_ip    = try(module.mx.public_ip, null)
    public_dns   = try(module.mx.public_dns, null)
    private_ip   = try(module.mx.private_ip, null)
    private_dns  = try(module.mx.private_dns, null)
    display_name = try(module.mx.display_name, null)
    role_arn     = try(module.mx.iam_role, null)
    ssh_command  = try("ssh -i ${module.key_pair.private_key_file_path} ${module.mx.ssh_user}@${module.mx.public_dns}", null)
  }
}

output "web_console_dam" {
  value = {
    public_url     = try(join("", ["https://", module.mx.public_dns, ":8083/"]), null)
    private_url    = try(join("", ["https://", module.mx.private_dns, ":8083/"]), null)
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
