output "public_ip" {
  description = "Public elastic IP address of the DSF instance"
  value       = module.mx.public_ip
  depends_on = [
    module.mx.ready
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF instance"
  value       = module.mx.private_ip
  depends_on = [
    module.mx.ready
  ]
}

output "display_name" {
  description = "Display name"
  value       = module.mx.display_name
}

output "ssh_user" {
  description = "SSH username"
  value       = module.mx.ssh_user
}

output "instance_id" {
  value = module.mx.instance_id
}

output "web_console_user" {
  value = "admin"
}

output "large_scale_mode" {
  value = var.large_scale_mode
}