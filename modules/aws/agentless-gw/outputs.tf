output "public_ip" {
  description = "Public elastic IP address of the DSF instance"
  value = module.gw_instance.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF instance"
  value = module.gw_instance.private_ip
}

output "public_dns" {
  description = "Public dns of elastic IP address of the DSF instance"
  value = module.gw_instance.public_dns
}

output "private_dns" {
  description = "Private dns address of the DSF instance"
  value = module.gw_instance.private_dns
}

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value       = module.gw_instance.iam_role
}

output "display_name" {
  description = "Display name"
  value = module.gw_instance.display_name
}

output "ssh_user" {
  description = "Ssh username"
  value = module.gw_instance.ssh_user
}

output "instance_id" {
  value = module.gw_instance.instance_id
}

output "sonarw_public_key" {
  description = "Sonarw user public key (used for federation, hadr, and more)"
  value = module.gw_instance.sonarw_public_key
}

output "sonarw_private_key" {
  description = "Sonarw user private key (used for federation, hadr, and more)"
  value = module.gw_instance.sonarw_private_key
}

output "jsonar_uid" {
  description = "Sonar node id"
  value = module.gw_instance.jsonar_uid
}
