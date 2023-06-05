output "dsf_admin_server" {
  value = {
    public_ip    = try(module.dra_admin.public_ip, null)
    public_dns   = try(module.dra_admin.public_dns, null)
    private_ip   = try(module.dra_admin.private_ip, null)
    private_dns  = try(module.dra_admin.private_dns, null)
    display_name = try(module.dra_admin.display_name, null)
    role_arn     = try(module.dra_admin.iam_role, null)
    ssh_command  = try("ssh ${module.dra_admin.ssh_user}@${module.dra_admin.public_dns}", null)
  }
}

output "web_console_dra" {
  value = {
    public_url  = try(join("", ["https://", module.dra_admin.public_ip, ":8443/"]), null)
    private_url = try(join("", ["https://", module.dra_admin.private_ip, ":8443/"]), null)
  }
}

output "dra_analytics" {
  sensitive = true
  value = {
    for idx, val in module.analytics_server_group : "analytics-${idx}" =>
    {
      private_ip    = try(val.analytics_private_ip, null)
      archiver_user = try(val.archiver_user, null)
    }
  }
}

output "dsf_private_ssh_key" {
  sensitive = true
  value     = try(module.key_pair.key_pair_private_pem, null)
}

output "dsf_private_ssh_key_file_path" {
  value = module.key_pair.private_key_file_path
}
