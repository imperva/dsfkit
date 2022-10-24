output "public_address" {
  value = module.hub_instance.public_address
}

output "private_address" {
  value = module.hub_instance.private_address
}

output "sg_id" {
  value = module.hub_instance.sg_id
}

output "sonarw_public_key" {
  value = ! var.hadr_secondary_node ? local.dsf_hub_ssh_federation_key : null
}

output "sonarw_secret" {
  value = {
    name = ! var.hadr_secondary_node ? resource.aws_secretsmanager_secret.dsf_hub_federation_private_key[0].name : var.hadr_main_hub_sonarw_secret.name
    arn = ! var.hadr_secondary_node ? resource.aws_secretsmanager_secret.dsf_hub_federation_private_key[0].arn : var.hadr_main_hub_sonarw_secret.arn
  }
}
