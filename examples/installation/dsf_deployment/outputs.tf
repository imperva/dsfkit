output "dsf_hubs" {
  value = {
    primary = {
      private_ip   = try(module.hub.private_ip, null)
      public_dns   = try(module.hub.public_dns, null)
      public_ip    = try(module.hub.public_ip, null)
      jsonar_uid   = try(module.hub.jsonar_uid, null)
      display_name = try(module.hub.display_name, null)
      role_arn     = try(module.hub.iam_role, null)
      ssh_command  = try("ssh -i ${module.key_pair_hub.key_pair_private_pem.filename} ${module.hub.ssh_user}@${module.hub.public_ip}", null)
    }
  }
}

output "dsf_hub_web_console" {
  value = {
    public_url    = try(join("", ["https://", module.hub.public_ip, ":8443/"]), null)
    admin_password = nonsensitive(local.web_console_admin_password)
  }
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_hub_ssh_key" {
  sensitive = true
  value     = try(module.key_pair_hub.key_pair_private_pem, null)
}
