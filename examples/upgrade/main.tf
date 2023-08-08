

module "sonar_upgrader"{
  source = "./modules/sonar_upgrader_python"
  agentless_gws = [
      {
        "ip" = "10.0.1.1"
        "ssh_user" = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key1.pem"
        "proxy" = {
          "ip" = "200.1.1.1"
          "ssh_user" = "ec2-user"
          "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        }
      }
  ]

  target_version = "4.12.0.10.0"
  # options
  run_preflight_validations = true
  run_postflight_validations = true
  custom_validations_scripts = ["validation1", "validation2"]
  run_upgrade = false
}
