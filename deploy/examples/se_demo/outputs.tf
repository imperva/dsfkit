output "dsf_agentless_gws" {
  value = { for idx, val in module.agentless_gw : "gw-${idx}" => {private_address = val.private_address, public_address = val.public_address, jsonar_uid = module.gw_install[idx].jsonar_uid}}
}

output "dsf_hubs" {
  value = {
      primary_hub = {
        public_address = module.hub.public_address
        private_address = module.hub.private_address
        jsonar_uid = module.hub_install["primary_hub"].jsonar_uid
      }
  }
}

output "dsf_hub_web_console_url" {
    value     = can(module.hub.public_address) ? join("", ["https://", module.hub.public_address, ":8443/" ]) : null
}

output "primary_hub_ssh_command" {
    value     = join("", ["ssh -i ${resource.local_sensitive_file.dsf_ssh_key_file.filename} ec2-user@", module.hub.public_address])
}

output "admin_password" {
  value = local.admin_password
  sensitive = true
}

output "deployment_name" {
  value = local.deployment_name
}

output "dsf_private_ssh_key" {
  sensitive = true
  value = module.key_pair.private_key_pem
}
