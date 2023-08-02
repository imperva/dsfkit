# output "dsf_agentless_gw_group" {
#   value = {
#     for idx, val in module.agentless_gw_group : "gw-${idx}" =>
#     {
#       private_ip = try(val.private_ip, null)
#       public_ip  = try(val.public_ip, null)
#       # private_dns  = try(val.private_dns, null)
#       jsonar_uid   = try(val.jsonar_uid, null)
#       display_name = try(val.display_name, null)
#       # role_arn     = try(val.iam_role, null)
#       ssh_command = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${local_sensitive_file.ssh_key.filename} -W %h:%p ${module.hub.ssh_user}@${module.hub.public_ip}' -i ${local_sensitive_file.ssh_key.filename} ${val.ssh_user}@${val.private_ip}", null)
#     }
#   }
# }

output "dsf_hubs" {
  value = {
    primary = {
      public_ip    = try(module.hub.public_ip, null)
      private_ip   = try(module.hub.private_ip, null)
      jsonar_uid   = try(module.hub.jsonar_uid, null)
      display_name = try(module.hub.display_name, null)
      #   role_arn     = try(module.hub.iam_role, null)
      ssh_command = try("ssh -i ${local_sensitive_file.ssh_key.filename} ${module.hub.ssh_user}@${module.hub.public_ip}", null)
    }
  }
}

output "dsf_hub_web_console" {
  value = {
    public_url     = try(join("", ["https://", module.hub.public_ip, ":8443/"]), null)
    private_url    = try(join("", ["https://", module.hub.private_ip, ":8443/"]), null)
    admin_password = nonsensitive(local.web_console_admin_password)
  }
}

output "dsf_private_ssh_key" {
  sensitive = true
  value     = try(tls_private_key.ssh_key.private_key_openssh, null)
}

output "dsf_private_ssh_key_file_name" {
  value = try(local_sensitive_file.ssh_key.filename, null)
}

