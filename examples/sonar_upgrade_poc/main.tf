module "sonar_upgrader"{
  source = "./modules/sonar_upgrader_python"
  agentless_gws = [
      {
        "host" = "10.0.1.131"
        "ssh_user" = "ec2-user"
        "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
        "proxy" = {
          "host" = "13.52.18.235"
          "ssh_user" = "ec2-user"
          "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
        }
      }
  ]

  target_version = "4.12.0.10.0"
  # options
  run_preflight_validations = true
  run_upgrade = false
  run_postflight_validations = false
  custom_validations_scripts = ["validation1"]
}
