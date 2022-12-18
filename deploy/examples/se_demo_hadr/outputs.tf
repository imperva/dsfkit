#output "dsf_agentless_gw_group" {
#  value = {
#    for idx, val in module.agentless_gw_group : "gw-${idx}" =>
#    {
#      private_address = try(val.private_address, null)
#      jsonar_uid      = try(val.jsonar_uid, null)
#      display_name    = try(val.display_name, null)
#      role_arn        = try(val.iam_role, null)
#      ssh_command     = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.key_pair.key_pair_private_pem.filename} -W %h:%p ec2-user@${module.hub.public_address}' -i ${module.key_pair.key_pair_private_pem.filename} ec2-user@${val.private_address}", null)
#    }
#  }
#}

output "dsf_hubs" {
  value = {
    primary = {
      public_address  = try(module.hub.public_address, null)
      private_address = try(module.hub.private_address, null)
      jsonar_uid      = try(module.hub.jsonar_uid, null)
      display_name    = try(module.hub.display_name, null)
      role_arn        = try(module.hub.iam_role, null)
      ssh_command     = try("ssh -i ${module.key_pair.key_pair_private_pem.filename} ec2-user@${module.hub.public_address}", null)
    }
    secondary = {
      public_address  = try(module.hub_secondary.public_address, null)
      private_address = try(module.hub_secondary.private_address, null)
      jsonar_uid      = try(module.hub_secondary.jsonar_uid, null)
      display_name    = try(module.hub_secondary.display_name, null)
      role_arn        = try(module.hub_secondary.iam_role, null)
      ssh_command     = try("ssh -i ${module.key_pair.key_pair_private_pem.filename} ec2-user@${module.hub_secondary.public_address}", null)
    }
  }
}

output "web_console_admin_password" {
  value = nonsensitive(local.web_console_admin_password)
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_private_ssh_key" {
  sensitive = true
  value     = try(module.key_pair.key_pair_private_pem, null)
}

output "dsf_hub_web_console_public_url" {
  value = try(join("", ["https://", module.hub.public_address, ":8443/"]), null)
}

output "dsf_hub_web_console_private_url" {
  value = try(join("", ["https://", module.hub.private_address, ":8443/"]), null)
}
