
output "hub_ip" { value = module.sonarw.public_address }
output "hub_uuid" { value = module.sonarw.jsonar_uid }
output "hub_display_name" { value = module.sonarw.display_name }
output "hub_iam_role" { value = module.sonarw.iam_role }
output "gw1_uuid" { value = module.sonarg1.jsonar_uid }
output "gw1_display_name" { value = module.sonarg1.display_name }
output "gw1_iam_role" { value = module.sonarg1.iam_role }
output "security_group_ingress_cidrs" { value = var.security_group_ingress_cidrs }