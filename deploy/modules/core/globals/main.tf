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

resource "time_static" "current_time" {}

resource "random_password" "pass" {
  length  = 15
  special = false
}


module "key_pair" {
  count                    = var.create_ssh_key ? 1 : 0
  source                   = "../key_pair"
  key_name_prefix          = "imperva-dsf-"
  create_private_key       = true
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
}