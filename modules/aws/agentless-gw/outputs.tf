output "public_ip" {
  value = module.gw_instance.public_ip
}

output "private_ip" {
  value = module.gw_instance.private_ip
}

output "public_dns" {
  value = module.gw_instance.public_dns
}

output "private_dns" {
  value = module.gw_instance.private_dns
}

output "iam_role" {
  description = "IAM Role ARN of the DSF Agentless Gateway node"
  value       = module.gw_instance.iam_role
}

output "sonarw_public_key" {
  value = module.gw_instance.sonarw_public_key
}

output "sonarw_private_key" {
  value = module.gw_instance.sonarw_private_key
}

output "jsonar_uid" {
  value = module.gw_instance.jsonar_uid
}

output "display_name" {
  value = module.gw_instance.display_name
}

output "ssh_user" {
  value = module.gw_instance.ssh_user
}