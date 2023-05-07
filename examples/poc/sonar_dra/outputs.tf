output "dsf_admin_server" {
  value = {
    public_ip    = try(module.dra_admin.public_ip, null)
    public_dns   = try(module.dra_admin.public_dns, null)
    private_ip   = try(module.dra_admin.private_ip, null)
    private_dns  = try(module.dra_admin.private_dns, null)
    display_name = try(module.dra_admin.display_name, null)
    role_arn     = try(module.dra_admin.iam_role, null)
    # todo - check why we cant connect with the registration password
#    ssh_command  = try("ssh -i ${module.key_pair.private_key_file_path} ${module.dra_admin.ssh_user}@${module.dra_admin.public_dns}", null)
  }
}

output "dsf_admin_server_web_console" {
  value = {
    public_url     = try(join("", ["https://", module.dra_admin.public_ip, ":8443/"]), null)
    private_url    = try(join("", ["https://", module.dra_admin.private_ip, ":8443/"]), null)
  }
}

output "dra_analytics" {
   sensitive = true
   value = {
   for idx, val in module.analytics_server_group : "analytics-${idx}" =>
    {
      private_ip        = try(val.analytics_private_ip, null)
      archiver_user     = try(val.archiver_user, null)
      archiver_password = try(val.archiver_password, null)
#      ssh_command       = try("ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.private_key_file_path} -W %h:%p ${module.dra_admin.ssh_user}@${module.dra_admin.public_ip}' -i ${module.key_pair.private_key_file_path} ${val.ssh_user}@${val.analytics_private_ip}", null)
    }
   }
}

output "dra_analytics_incoming_folder_path" {
  value = "/opt/itpba/incoming"
}

output "dsf_private_ssh_key" {
  sensitive = true
  value     = try(module.key_pair.key_pair_private_pem, null)
}

output "dsf_private_ssh_key_file_path" {
  value = module.key_pair.private_key_file_path
}
