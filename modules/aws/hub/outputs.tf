output "public_ip" {
  description = "Public elastic IP address of the DSF instance"
  value       = module.hub_instance.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF instance"
  value       = module.hub_instance.private_ip
}

output "public_dns" {
  description = "Public dns of elastic IP address of the DSF instance"
  value       = module.hub_instance.public_dns
}

output "private_dns" {
  description = "Private dns address of the DSF instance"
  value       = module.hub_instance.private_dns
}

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value       = module.hub_instance.iam_role
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
  value       = module.hub_instance.sonarw_public_key
}

output "sonarw_private_key" {
  description = "The private key (also known as the sonarw private SSH key) should be used for federation and for connecting secondary hadr DSF Hub"
  value       = module.hub_instance.sonarw_private_key
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