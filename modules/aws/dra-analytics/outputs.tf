output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = local.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = local.private_ip
}

output "public_dns" {
  description = "Public DNS of the elastic IP address of the DSF base instance"
  value       = local.public_dns
}

output "private_dns" {
  description = "Private DNS of the elastic IP address of the DSF base instance"
  value       = aws_network_interface.eni.private_dns_name
}

output "archiver_user" {
  value = var.archiver_user
}

output "incoming_folder_path" {
  value = local.incoming_folder_path
}

output "ssh_user" {
  value = "cbadmin"
}
