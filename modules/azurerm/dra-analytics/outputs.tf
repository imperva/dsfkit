output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = local.public_ip
  depends_on = [
    azurerm_network_interface_security_group_association.nic_sg_association,
#    azurerm_virtual_machine_data_disk_attachment.data_disk_attachment,
    azurerm_role_assignment.vm_identity_role_assignment
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = local.private_ip
  depends_on = [
    azurerm_network_interface_security_group_association.nic_sg_association,
#    azurerm_virtual_machine_data_disk_attachment.data_disk_attachment,
    azurerm_role_assignment.vm_identity_role_assignment
  ]
}

#output "public_dns" {
#  description = "Public DNS of the elastic IP address of the DSF base instance"
#  value       = local.public_dns
#}
#
#output "private_dns" {
#  description = "Private DNS of the elastic IP address of the DSF base instance"
#  value       = aws_network_interface.eni.private_dns_name
#}
#


output "archiver_user" {
  value = var.archiver_user
}

output "archiver_password" {
  value = var.archiver_password
}

output "incoming_folder_path" {
  value = local.incoming_folder_path
}

output "ssh_user" {
  value = "cbadmin"
}
