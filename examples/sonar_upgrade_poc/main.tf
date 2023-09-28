module "sonar_upgrader" {
  source = "./modules/sonar_upgrader_python"
  agentless_gws = [
    {
      "main" = {
        "host"                      = "10.0.1.1"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
      },
      "dr" = {
        "host"                      = "10.2.1.1"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
      }
    },
    {
      "main" = {
        "host"                      = "10.0.1.2"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        "proxy"                     = {
          "host"                      = "52.8.8.8"
          "ssh_user"                  = "ec2-user"
          "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        }
      },
      "dr" = {
        "host"                      = "10.2.1.2"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        "proxy"                     = {
          "host"                      = "52.8.8.8"
          "ssh_user"                  = "ec2-user"
          "ssh_private_key_file_path" = "/home/ssh_key2.pem"
        }
      }
    },
    {
      "main" = {
        "host"                      = "10.0.1.3"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
      }
    },
    {
      "dr" = {
        "host"                      = "10.0.1.4"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
      }
    }
  ]
  dsf_hubs = [
    {
      "main" = {
        "host"                      = "52.8.8.8"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
      },
      "dr" = {
        "host"                      = "52.8.8.9"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
      },
      "minor" = {
        "host"                      = "52.8.8.10"
        "ssh_user"                  = "ec2-user"
        "ssh_private_key_file_path" = "/home/ssh_key2.pem"
      }
    }
  ]

  target_version = "4.12.0.10.0"
  # options
  test_connection = true
  run_preflight_validations = true
  run_upgrade = true
  run_postflight_validations = true
}
