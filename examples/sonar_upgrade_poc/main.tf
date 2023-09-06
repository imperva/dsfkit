module "sonar_upgrader"{
  source = "./modules/sonar_upgrader_python"
  agentless_gws = [
      {
        "host" = "10.0.1.1"
        "ssh_user" = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        "proxy" = {
          "host" = "52.8.8.8"
          "ssh_user" = "ec2-user"
          "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        }
      },
      {
        "host" = "10.0.1.2"
        "ssh_user" = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        "proxy" = {
          "ip" = "52.8.8.8"
          "ssh_user" = "ec2-user"
          "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        }
      },
      {
        "host" = "10.0.1.3"
        "ssh_user" = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        "proxy" = {
          "ip" = "52.8.8.8"
          "ssh_user" = "ec2-user"
          "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        }
      }
  ]
  dsf_hubs = [
    {
      "host" = "52.8.8.8"
      "ssh_user" = "ec2-user"
      "ssh_private_key_file_path" = "/home/ssh_key2.pem"
    }
  ]

  target_version = "4.12.0.10.0"
  # options
  run_preflight_validations = true
  run_upgrade = true
  run_postflight_validations = true
  custom_validations_scripts = ["validation1"]
}
