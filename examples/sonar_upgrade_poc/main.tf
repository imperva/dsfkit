module "sonar_upgrader" {
  source = "./modules/sonar_upgrader_python"
  agentless_gws = [
      {
        "main" = {
          "host"                      = "10.0.1.156"
          "ssh_user"                  = "ec2-user"
          "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
          "proxy"                     = {
            "host"                      = "18.178.79.43"
            "ssh_user"                  = "ec2-user"
            "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
          }
        }
        "dr" = {
          "host"                      = "10.0.2.194"
          "ssh_user"                  = "ec2-user"
          "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
          "proxy"                     = {
            "host"                      = "18.178.79.43"
            "ssh_user"                  = "ec2-user"
            "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
          }
        }
      },
      {
        "dr" = {
          "host"                      = "10.0.2.240"
          "ssh_user"                  = "ec2-user"
          "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
          "proxy"                     = {
            "host"                      = "18.178.79.43"
            "ssh_user"                  = "ec2-user"
            "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
          }
        }
      }
  ]
  dsf_hubs = [
    {
      "main" = {
        "host"                      = "18.178.79.43"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
      },
      "dr" = {
        "host"                      = "52.195.240.48"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/Users/linda.nasredin/cnc_workspace/dsfkit/examples/poc/sonar_hadr_deployment/ssh_keys/dsf_ssh_key-default"
      }
    }
  ]

  target_version = "4.12.0.10.0"
  # options
  run_preflight_validations = true
  run_upgrade = true
  run_postflight_validations = true
  run_clean_old_deployments = true
  custom_validations_scripts = ["validation1"]
}
