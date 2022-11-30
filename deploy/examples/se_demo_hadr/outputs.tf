output "dsf_agentless_gw_group" {
  value = {
    for idx, val in module.agentless_gw_group : "gw-${idx}" =>
    {
      private_address = val.private_address,
      jsonar_uid      = val.jsonar_uid,
      display_name    = val.display_name
      role_arn        = val.iam_role
    }
  }
}

output "dsf_hubs" {
  value = {
    primary = {
      public_address  = module.hub.public_address
      private_address = module.hub.private_address
      jsonar_uid      = module.hub.jsonar_uid
      display_name    = module.hub.display_name
      role_arn        = module.hub.iam_role
    }
    secondary = {
      public_address  = module.hub_secondary.public_address
      private_address = module.hub_secondary.private_address
      jsonar_uid      = module.hub_secondary.jsonar_uid
      display_name    = module.hub_secondary.display_name
      role_arn        = module.hub_secondary.iam_role
    }
  }
}

output "admin_password" {
  value = nonsensitive(local.admin_password)
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_private_ssh_key" {
  sensitive = true
  value     = module.globals.key_pair_private_pem
}

output "dsf_hub_web_console_url" {
  value = try(join("", ["https://", module.hub.public_address, ":8443/"]), null)
}

output "ssh_command_hub" {
  value = "ssh -i ${module.globals.key_pair_private_pem.filename} ec2-user@${module.hub.public_address}"
}

output "ssh_command_secondary_hub" {
  value = "ssh -i ${module.globals.key_pair_private_pem.filename} ec2-user@${module.hub_secondary.public_address}"
}

output "ssh_command_gw" {
  value = try("ssh -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${module.globals.key_pair_private_pem.filename} -W %h:%p ec2-user@${module.hub.public_address}' -i ${module.globals.key_pair_private_pem.filename} ec2-user@${module.agentless_gw_group[0].private_address}", null)
}