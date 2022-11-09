resource "random_id" "salt" {
  byte_length = 2
}

data "local_file" "myip_file" { # data "http" doesn't work as expected on Terraform cloud platform
  filename = "myip-${terraform.workspace}"
  depends_on = [
    resource.null_resource.myip
  ]
}

resource "null_resource" "myip" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command     = "curl http://ipv4.icanhazip.com > myip-${terraform.workspace}"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "time_static" "current_time" {}

resource "random_password" "pass" {
  length  = 15
  special = false
}


module "key_pair" {
  source             = "terraform-aws-modules/key-pair/aws"
  key_name_prefix    = "imperva-dsf-"
  create_private_key = true
}

resource "local_sensitive_file" "dsf_ssh_key_file" {
  content         = module.key_pair.private_key_pem
  file_permission = 400
  filename        = "ssh_keys/dsf_hub_ssh_key-${terraform.workspace}"
}


output "salt" {
  value = resource.random_id.salt.hex
}

output "my_ip" {
  value = data.local_file.myip_file.content
}

output "now" {
  value = resource.time_static.current_time.id
}

output "random_password" {
  value = resource.random_password.pass.result
}

output "key_pair" {
  value = module.key_pair
}

output "key_pair_private_pem" {
  value = resource.local_sensitive_file.dsf_ssh_key_file
}

output "tags" {
  value = {
    terraform_workspace                = terraform.workspace
    vendor                             = "Imperva"
    product                            = "EDSF"
    terraform                          = "true"
    environment                        = "demo"
    creation_timestamp                 =  resource.time_static.current_time.id
  }
}


# output "resource_types" {
#     value = {
#     "HUB"  = "hub"
#     "GW" = "gw"
#   }
# }