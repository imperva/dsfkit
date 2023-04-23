
resource "random_password" "passphrase" {
  length  = 32
  special = false
}

resource "random_id" "encryption_salt" {
  byte_length = 8
}

data "local_sensitive_file" "license_file" {
  filename = var.license_file
}

locals {
  cmd = <<EOF
  echo '{"cipher_text": "'$(echo '${data.local_sensitive_file.license_file.content}' | openssl aes-256-cbc -pass pass:${random_password.passphrase.result} -md md5 -S ${random_id.encryption_salt.hex} | base64 | tr -d "\n" )'"}'
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