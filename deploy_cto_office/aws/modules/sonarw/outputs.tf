output "public_ip" {
  description = "Public Elastic IP address of the DSF base instance"
  value       = module.hub_instance.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = module.hub_instance.private_ip
}

output "uuid" {
  description = "UUID of sonar instance"
  value       = random_uuid.uuid.result
}

output "display_name" {
  description = "UUID of sonar instance"
  value       = var.name
}