output "public_ip" {
  description = "Public elastic IP address of the DSF instance"
  value       = local.public_ip
#  depends_on = [
#    azurerm_network_interface_security_group_association.nic_sg_association,
#    azurerm_role_assignment.vm_identity_role_assignment
#  ]
}

output "private_ip" {
  description = "Private IP address of the DSF instance"
  value       = local.private_ip
  depends_on = [
    azurerm_network_interface_security_group_association.nic_sg_association,
    azurerm_role_assignment.vm_identity_role_assignment
  ]
}

output "display_name" {
  value = var.name
}

output "ssh_user" {
  value = "cbadmin"
}

output "ssh_password" {
  value = var.admin_ssh_password
}

# not sure
output "instance_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "admin_image_id" {
  value = local.image_id
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