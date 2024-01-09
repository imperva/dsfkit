output "public_ip" {
  description = "Public IP address of the DSF instance"
  value       = module.hub_instance.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF instance"
  value       = module.hub_instance.private_ip
}

output "principal_id" {
  description = "Principal ID of the DSF node"
  value       = module.hub_instance.principal_id
}

output "display_name" {
  description = "Display name of the instance under the DSF web console"
  value       = module.hub_instance.display_name
}

output "ssh_user" {
  description = "Ssh username"
  value       = module.hub_instance.ssh_user
}

output "instance_id" {
  value = module.hub_instance.instance_id
}

output "sonarw_public_key" {
  description = "The public key (also known as the sonarw public SSH key) should be used for federation and for connecting an Agentless Gateway"
  value       = module.hub_instance.main_node_sonarw_public_key
}

output "sonarw_private_key" {
  description = "The private key (also known as the sonarw private SSH key) should be used for federation and for connecting DR hadr DSF Hub"
  value       = module.hub_instance.main_node_sonarw_private_key
}

output "jsonar_uid" {
  description = "Id of the instance in DSF portal"
  value       = module.hub_instance.jsonar_uid
}

output "access_tokens" {
  value     = module.hub_instance.access_tokens
  sensitive = true
}

output "web_console_user" {
  value = "admin"
}
