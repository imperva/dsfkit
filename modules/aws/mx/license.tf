
variable "license_file" {
  default = "license.mprv"
}

resource "random_password" "pass" {
  length  = 32
  special = false
}

resource "random_password" "encryption_salt" {
  length  = 16
  special = false
}

locals {
    cmd= <<EOF
  echo '{"cipher_text": "'$(openssl aes-256-cbc -in ${var.license_file} -pass pass:${random_password.pass.result} -md md5 -S ${random_password.encryption_salt.result} | base64 -w0)'"}'
EOF
}

data "external" "encrypted_license" {
  program = ["bash", "-c", local.cmd]

  query = {
    cipher_text = "cipher_text"
  }
}