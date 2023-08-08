output "agentless_gw_list" {
  value = var.agentless_gws
}

output "hub_list" {
  value = var.dsf_hubs
}

output "target_version" {
  value = var.target_version
}

output "run_preflight_validations" {
  value = var.run_preflight_validations
}

output "run_postflight_validations" {
  value = var.run_postflight_validations
}

output "custom_validations_scripts" {
  value = var.custom_validations_scripts
}
