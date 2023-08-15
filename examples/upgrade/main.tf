

module "sonar_upgrader"{
  source = "./modules/sonar_upgrader_python"
  agentless_gws = [
      {
        "ip" = "10.0.1.231"
        "ssh_user" = "ec2-user"
        "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_basic_deployment/ssh_keys/dsf_ssh_key-default"
        "proxy" = {
          "ip" = "52.8.79.39"
          "ssh_user" = "ec2-user"
          "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_basic_deployment/ssh_keys/dsf_ssh_key-default"
        }
      },
      {
        "ip" = "10.0.1.223"
        "ssh_user" = "ec2-user"
        "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_basic_deployment/ssh_keys/dsf_ssh_key-default"
        "proxy" = {
          "ip" = "52.8.79.39"
          "ssh_user" = "ec2-user"
          "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_basic_deployment/ssh_keys/dsf_ssh_key-default"
        }
      },
      {
        "ip" = "10.0.1.109"
        "ssh_user" = "ec2-user"
        "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_basic_deployment/ssh_keys/dsf_ssh_key-default"
        "proxy" = {
          "ip" = "52.8.79.39"
          "ssh_user" = "ec2-user"
          "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_basic_deployment/ssh_keys/dsf_ssh_key-default"
        }
      }
  ]
  dsf_hubs = [
    {
      "ip" = "52.8.79.39"
      "ssh_user" = "ec2-user"
      "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_basic_deployment/ssh_keys/dsf_ssh_key-default"
    }
  ]

  target_version = "4.13.0.10.0-rc5"
  # options
  run_preflight_validations = true
  run_postflight_validations = true
  custom_validations_scripts = ["validation1"]
  run_upgrade = true
}
