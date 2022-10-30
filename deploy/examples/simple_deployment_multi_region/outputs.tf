output "dsf_hub_eip" {
    value = module.hub.public_address
}

output "dsf_gw_public_ip" {
  value = [
    for gw in module.agentless_gw : gw.public_address
  ]
}

output "dsf_gw_private_ip" {
  value = [
    for gw in module.agentless_gw : gw.private_address
  ]
}

output "hub_web_console_url" {
    value     = can(module.hub.public_address) ? join("", ["https://", module.hub.public_address, ":8443/" ]) : null
}

output "hub_ssh_command" {
    value     = join("", ["ssh -i ${resource.local_sensitive_file.dsf_hub_ssh_key_file.filename} ec2-user@", module.hub.public_address])
}

