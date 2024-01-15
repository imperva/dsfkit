output "public_ip" {
  description = "Public elastic IP address of the DSF instance"
  value       = local.public_ip
  depends_on = [
    azurerm_network_interface_security_group_association.nic_sg_association,
    azurerm_virtual_machine_data_disk_attachment.data_disk_attachment,
#    azurerm_role_assignment.vm_identity_storage_role_assignment
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF instance"
  value       = local.private_ip
  depends_on = [
    azurerm_network_interface_security_group_association.nic_sg_association,
    azurerm_virtual_machine_data_disk_attachment.data_disk_attachment,
#    azurerm_role_assignment.vm_identity_storage_role_assignment
  ]
}

#output "public_dns" {
#  description = "Public DNS of the elastic IP address of the DSF instance"
#  value       = null
#}

#output "private_dns" {
#  description = "Private DNS of the elastic IP address of the DSF instance"
#  value       = null
#}

#output "principal_id" {
#  description = "Principal ID of the DSF node"
#  value       = azurerm_linux_virtual_machine.vm.identity[0].principal_id
#}

output "display_name" {
  value = var.name
}

output "ssh_user" {
  value = "cbadmin"
}

output "ssh_password" {
  value = var.admin_password
}

# not sure
output "instance_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

#output "ready" {
#  description = <<-EOF
#    Indicates when module is "ready"
#  EOF
#  value       = "ready"
#  depends_on = [
#    null_resource.readiness
#  ]
#}