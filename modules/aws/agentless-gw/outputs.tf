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
  description = "IAM Role ARN of the DSF agentless gateway node"
  value = module.gw_instance.iam_role
}

output "primary_gw_sonarw_public_key" {
  value = module.gw_instance.primary_node_sonarw_public_key
}

output "primary_gw_sonarw_private_key" {
  value = module.gw_instance.primary_node_sonarw_private_key
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