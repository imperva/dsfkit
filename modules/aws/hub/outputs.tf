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
  value = local.role_arn
}

output "federation_public_key" {
  value = local.dsf_hub_ssh_public_federation_key
}

output "federation_private_key" {
  value = local.dsf_hub_ssh_private_federation_key
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