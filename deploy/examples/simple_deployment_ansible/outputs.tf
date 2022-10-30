output "dsf_hub_public_address" {
  value = module.hub.public_address
}

output "dsf_gw_public_address" {
  value = [
    for gw in module.agentless_gw : gw.public_address
  ]
}

output "dsf_gw_private_address" {
  value = [
    for gw in module.agentless_gw : gw.private_address
  ]
}

output "dsf_hub_web_console_url" {
  value     = can(module.hub.public_address) ? join("", ["https://", module.hub.public_address, ":8443/" ]) : null
}

output "hub_ssh_command" {
  value = join("", ["ssh -i ${resource.local_sensitive_file.dsf_ssh_key_file.filename} ec2-user@", module.hub.public_address])
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
  value = module.key_pair.private_key_openssh
}
