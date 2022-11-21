output "dsf_agentless_gw_group" {
  value = { for idx, val in module.agentless_gw_group : "gw-${idx}" => { private_address = val.private_address, jsonar_uid = val.jsonar_uid } }
}

output "dsf_hubs" {
  value = {
    primary_hub = {
      public_address  = module.hub.public_address
      private_address = module.hub.private_address
      jsonar_uid      = module.hub.jsonar_uid
    }
  }
}

output "dsf_hub_web_console_url" {
  value = try(join("", ["https://", module.hub.public_address, ":8443/"]), null)
}

output "hub_primary_ssh_command" {
  value = try(join("", ["ssh -i ${module.globals.key_pair_private_pem.filename} ec2-user@", module.hub.public_address]), null)
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
