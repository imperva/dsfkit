output "public_ip" {
  description = "Public IP address of the CipherTrust Manager instance"
  # logic is in the output (not a local) to avoid destroy-time locals dependency issues
  value       = var.attach_persistent_public_ip ? aws_eip.dsf_instance_eip[0].public_ip : aws_instance.cipthertrust_manager_instance.public_ip
  depends_on = [
    aws_eip.dsf_instance_eip,
    aws_instance.cipthertrust_manager_instance
  ]
}

output "private_ip" {
  description = "Private IP address of the CipherTrust Manager instance"
  # logic is in the output (not a local) to avoid destroy-time locals dependency issues
  value       = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null
  depends_on = [
    aws_network_interface.eni,
    aws_instance.cipthertrust_manager_instance
  ]
}

output "public_dns" {
  description = "Public DNS of the IP address of the CipherTrust Manager instance"
  # logic is in the output (not a local) to avoid destroy-time locals dependency issues
  value       = var.attach_persistent_public_ip ? aws_eip.dsf_instance_eip[0].public_dns : aws_instance.cipthertrust_manager_instance.public_dns
  depends_on = [
    aws_eip.dsf_instance_eip,
    aws_instance.cipthertrust_manager_instance
  ]
}

output "private_dns" {
  description = "Private DNS of the IP address of the CipherTrust Manager instance"
  value       = aws_network_interface.eni.private_dns_name
  depends_on = [
    aws_network_interface.eni,
    aws_instance.cipthertrust_manager_instance
  ]
}

output "instance_id" {
  value = aws_instance.cipthertrust_manager_instance.id
}

output "display_name" {
  value = aws_instance.cipthertrust_manager_instance.tags.Name
}

output "ssh_user" {
  value = var.ssh_user
}

output "web_console_user" {
  value = local.web_console_username
}