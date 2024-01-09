
resource "random_password" "passphrase" {
  length  = 32
  special = false
}

resource "random_id" "encryption_salt" {
  byte_length = 8
}

data "local_sensitive_file" "license_file" {
  filename = var.license
}

locals {
  license_passphrase = random_password.passphrase.result
  license_content    = data.local_sensitive_file.license_file.content
  encrypted_license  = data.external.encrypted_license.result.cipher_text
}

locals {
  cmd = <<EOF
  cipher_text=$(echo '${local.license_content}' | openssl aes-256-cbc -S ${random_id.encryption_salt.hex} -pass pass:${random_password.passphrase.result} -md md5 | base64 | tr -d "\n" )
  # Add cipher text Salt prefix in case it wasn't created (happens in OpenSSL 3.0.2)
  if [[ ! "$cipher_text" == "U2FsdGVkX1"* ]]; then # "U2FsdGVkX1" is b64 encoded cipher text header - "Salted__"
    # Encode the concatenated binary data as base64
    cipher_text=$((echo -n "Salted__"; echo -n ${random_id.encryption_salt.b64_std} | base64 -d; echo -n "$cipher_text" | base64 -d) | base64 | tr -d "\n")
  fi
  echo '{"cipher_text": "'$cipher_text'"}'
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