output "analytics_private_ip" {
  value = aws_instance.dsf_base_instance.private_ip
}

output "archiver_user" {
  value = var.archiver_user
}

output "archiver_password" {
  sensitive = true
  value = var.archiver_password
}

output "incoming_folder_path" {
  value = "/opt/itpba/incoming"
}