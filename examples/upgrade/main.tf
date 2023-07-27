

module "sonar_upgrader"{
  # map of target machines 
  source = "./modules/sonar_upgrader_python"
  target_agentless_gws = [
      {
        "ip" = "10.0.1.1" # can be private or public
        "ssh_private_key_file_path" = "/home/ssh_key1.pem"
        "proxy" = {
          "ip" = "200.1.1.1" # can be private or public
          "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        }
      }
  ]

  # target version
  target_version = 4.12
  # options
  run_preflight_validations = true
  run_postflight_validations = true
  custom_validations_scripts = ["validation1", "validation2"]
}



