output "public_ip" {
  description = "Public elastic IP address of the DSF instance"
  value       = local.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF instance"
  value       = local.private_ip
}


output "ssh_password" {
  value = var.admin_ssh_password
}


output "admin_image_id" {
  value = local.image_id
}

output "display_name" {
  value = var.name
}

output "ssh_user" {
  value = "cbadmin"
}

