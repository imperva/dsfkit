output "private_ip" {
  description = "Private IP address of the instance"
  value       = azurerm_linux_virtual_machine.agent.private_ip_address
  depends_on = [
    azurerm_network_interface_security_group_association.nic_ip_association,
  ]
}

output "display_name" {
  value = azurerm_linux_virtual_machine.agent.tags["Name"]
}

output "ssh_user" {
  value = local.vm_user
}

output "instance_id" {
  value = azurerm_linux_virtual_machine.agent.id
}

output "db_type" {
  value = local.db_type
}

output "os_type" {
  value = local.os_type
}
