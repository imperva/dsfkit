output "public_address" {
  value = module.hub_instance.public_address
}

output "private_address" {
  value = module.hub_instance.private_address
}

output "sg_id" {
  value = module.hub_instance.sg_id
}

output "iam_role" {
  value = resource.aws_iam_role.dsf_hub_role.arn
}

output "sonarw_public_key" {
  value = ! var.hadr_secondary_node ? local.dsf_hub_ssh_federation_key : null
}

output "sonarw_secret" {
  value = {
    name = local.secret_aws_name
    arn  = local.secret_aws_arn
  }
}
