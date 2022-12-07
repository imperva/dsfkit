resource "random_id" "salt" {
  byte_length = 2
}

resource "null_resource" "postpone_data_to_apply_phase" {
  triggers = {
    always_run = "${timestamp()}"
  }
}

data "http" "workstation_public_ip" {
  url = "http://ipv4.icanhazip.com"
  depends_on = [
    null_resource.postpone_data_to_apply_phase
  ]
}

data "aws_caller_identity" "current" {}

resource "time_static" "current_time" {}

resource "random_password" "pass" {
  length  = 15
  special = false
}