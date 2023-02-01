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

output "jsonar_uid" {
  value = module.gw_instance.jsonar_uid
}

output "display_name" {
  value = module.gw_instance.display_name
}

output "ssh_user" {
  value = module.gw_instance.ssh_user
}