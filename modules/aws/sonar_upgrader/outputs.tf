output "agentless_gw_list" {
  value = var.agentless_gws
}

output "hub_list" {
  value = var.dsf_hubs
}

output "target_version" {
  value = var.target_version
}

output "test_connection" {
  value = var.test_connection
}

output "run_preflight_validations" {
  value = var.run_preflight_validations
}

output "run_upgrade" {
  value = var.run_upgrade
}

output "run_postflight_validations" {
  value = var.run_postflight_validations
}

output "clean_old_deployments" {
  value = var.clean_old_deployments
}

