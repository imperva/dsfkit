
resource "random_password" "passphrase" {
  length  = 32
  special = false
}

resource "random_id" "encryption_salt" {
  byte_length = 8
}

locals {
  cmd = <<EOF
  echo '{"cipher_text": "'$(openssl aes-256-cbc -in ${var.license_file} -pass pass:${random_password.passphrase.result} -md md5 -S ${random_id.encryption_salt.hex} | base64 -w0)'"}'
EOF
}


data "external" "encrypted_license" {
  program = ["bash", "-c", local.cmd]

  query = {
    cipher_text = "cipher_text"
  }

  lifecycle {
    postcondition {
      condition     = self.result.cipher_text != ""
      error_message = "Failed to encrypt license"
    }
  }
}