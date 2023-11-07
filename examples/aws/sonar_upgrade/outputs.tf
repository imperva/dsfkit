output "agentless_gws" {
  value = module.sonar_upgrader.agentless_gws
}

output "dsf_hubs" {
  value = module.sonar_upgrader.dsf_hubs
}

output "target_version" {
  value = module.sonar_upgrader.target_version
}

output "test_connection" {
  value = module.sonar_upgrader.test_connection
}

output "run_preflight_validations" {
  value = module.sonar_upgrader.run_preflight_validations
}

output "run_upgrade" {
  value = module.sonar_upgrader.run_upgrade
}

output "run_postflight_validations" {
  value = module.sonar_upgrader.run_postflight_validations
}

#output "clean_old_deployments" {
#  value = module.sonar_upgrader.clean_old_deployments
#}

output "stop_on_failure" {
  value = module.sonar_upgrader.stop_on_failure
}

output "tarball_location" {
  value = var.tarball_location
}

output "summary" {
  value = try(jsondecode(file("upgrade_status.json")), null)
}