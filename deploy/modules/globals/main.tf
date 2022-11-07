provider "aws" {
}

data "aws_region" "current" {}

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

data "aws_caller_identity" "current" {}

output "current_region" {
  value = data.aws_region.current
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

output "caller_identity" {
  value = data.aws_caller_identity.current
}