output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = local.public_ip
  depends_on = [
    azurerm_network_interface_security_group_association.nic_ip_association,
    azurerm_virtual_machine_data_disk_attachment.data_disk_attachment,
    azurerm_role_assignment.dsf_base_storage_role_assignment
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = local.private_ip
  depends_on = [
    azurerm_network_interface_security_group_association.nic_ip_association,
    azurerm_virtual_machine_data_disk_attachment.data_disk_attachment,
    azurerm_role_assignment.dsf_base_storage_role_assignment
  ]
}

output "principal_id" {
  description = "Principal ID of the DSF node"
  value       = azurerm_linux_virtual_machine.dsf_base_instance.identity[0].principal_id
}

output "main_node_sonarw_public_key" {
  value = local.main_node_sonarw_public_key
}

output "main_node_sonarw_private_key" {
  value = local.main_node_sonarw_private_key
}

output "jsonar_uid" {
  value = random_uuid.jsonar_uuid.result
}

output "display_name" {
  value = local.display_name
}

output "ssh_user" {
  value = local.vm_user
}

output "instance_id" {
  value = azurerm_linux_virtual_machine.dsf_base_instance.id
}

output "access_tokens" {
  value = { for val in local.access_tokens_array : val.name => {
    name        = val.name
    token       = val.token
    secret_name = val.secret_name
    }
  }
  sensitive = true
}

output "ready" {
  description = <<-EOF
    Indicates when module is "ready"
  EOF
  value       = "ready"
  depends_on = [
    null_resource.readiness
  ]
}