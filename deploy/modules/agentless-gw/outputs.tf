output "public_address" {
  value = module.gw_instance.public_address
}

output "private_address" {
  value = module.gw_instance.private_address
}

output "iam_role" {
  value = resource.aws_iam_role.dsf_gw_role.arn
}

output "jsonar_uid" {
  value = module.gw_instance.jsonar_uid
}

output "display_name" {
  value = module.gw_instance.display_name
}