output "dsf_hub" {
  value = {
    private_ip   = try(module.hub_primary.private_ip, null)
    jsonar_uid   = try(module.hub_primary.jsonar_uid, null)
    display_name = try(module.hub_primary.display_name, null)
    role_arn     = try(module.hub_primary.iam_role, null)
    ssh_command  = try("ssh -i ${nonsensitive(module.key_pair_hub.key_pair_private_pem.filename)} ${module.hub_primary.ssh_user}@${module.hub_primary.private_ip}", null)
  }
}

output "dsf_hub_web_console" {
  value = {
    private_url    = try(join("", ["https://", module.hub_primary.private_ip, ":8443/"]), null)
    admin_password = nonsensitive(local.web_console_admin_password)
  }
}

output "hub_sonarw_public_key" {
  value = try(module.hub_primary.sonarw_public_key, null)
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_hub_ssh_key" {
  sensitive = true
  value     = module.key_pair_hub.key_pair_private_pem
}
