output "public_ip" {
  value = module.hub_instance.public_ip
}

output "private_ip" {
  value = module.hub_instance.private_ip
}

output "public_dns" {
  value = module.hub_instance.public_dns
}

output "private_dns" {
  value = module.hub_instance.private_dns
}

output "sg_id" {
  value = module.hub_instance.sg_id
}

output "iam_role" {
  description = "IAM Role ARN of the DSF Hub node"
  value       = module.hub_instance.iam_role
}

output "sonarw_public_key" {
  value = module.hub_instance.sonarw_public_key
}

output "sonarw_private_key" {
  value = module.hub_instance.sonarw_private_key
}

output "jsonar_uid" {
  value = module.hub_instance.jsonar_uid
}

output "display_name" {
  value = module.hub_instance.display_name
}

output "ssh_user" {
  value = module.hub_instance.ssh_user
}

output "access_tokens" {
  value = module.hub_instance.access_tokens
  sensitive = true
}