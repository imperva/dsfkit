output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = try(data.azurerm_public_ip.vm_public_ip[0].ip_address, null)
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = azurerm_network_interface.nic.private_ip_address
}

output "sonarw_public_key" {
  value = local.primary_node_sonarw_public_key
}

output "sonarw_private_key" {
  value = local.primary_node_sonarw_private_key
}

output "jsonar_uid" {
  value = random_uuid.uuid.result
}

output "display_name" {
  value = local.display_name
}

output "ssh_user" {
  value = local.vm_user
}