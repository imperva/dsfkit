
output "hub_ip" { value = module.sonarw.public_ip }
output "hub_uuid" { value = module.sonarw.uuid }
output "hub_display_name" { value = module.sonarw.display_name }
output "gw1_uuid" { value = module.sonarg1.uuid }
output "gw1_display_name" { value = module.sonarg1.display_name }
output "security_group_ingress_cidrs" { value = var.security_group_ingress_cidrs }