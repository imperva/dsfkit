output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = local.public_ip
  depends_on = [
    azurerm_network_interface_security_group_association.nic_ip_association,
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = local.private_ip
  depends_on = [
    azurerm_network_interface_security_group_association.nic_ip_association,
  ]
}

output "display_name" {
  value = local.display_name
}

output "ssh_user" {
  value = var.vm_user
}

output "instance_id" {
  value = azurerm_linux_virtual_machine.dsf_base_instance.id
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