output "public_ip" {
  description = "Public elastic IP address of the CipherTrust Manager instance"
  value       = local.public_ip
}

output "private_ip" {
  description = "Private IP address of the CipherTrust Manager instance"
  value       = local.private_ip
}

output "public_dns" {
  description = "Public DNS of the elastic IP address of the CipherTrust Manager instance"
  value       = local.public_dns
}

output "private_dns" {
  description = "Private DNS of the IP address of the CipherTrust Manager instance"
  value       = aws_network_interface.eni.private_dns_name
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