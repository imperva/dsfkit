

module "sonar_upgrader"{
  # map of target machines 
  source = "../upgrade/modules/sonar_upgrader"
  target_gws_by_id = [
      {
        "id" = "instance-id-111232"
        "ssh_key" = "ssh_key"
      },
      {
        "id" = "instance-id-d13332"
        "ssh_key" = "ssh_key"
      }
    ]

    target_hubs_by_id = [{
      "id" = "instance-id-a"
      "ssh_key" = "ssh_key"
    },{
      "id" = "instance-id-b"
      "ssh_key" = "ssh_key"
    }]

  # target version
  target_version = 4.15
  # options
  run_preflight_validation = true
  run_postflight_validation = true
  custom_validations_scripts = ["path1","path2"]
}



