resource "aws_kms_key" "password_kms" {
  description             = "${var.name} - DAM kms"
  deletion_window_in_days = 10
  tags                    = var.tags
}

resource "aws_kms_ciphertext" "encrypted_mx_password" {
  key_id    = aws_kms_key.password_kms.key_id
  plaintext = local.mx_password
}

resource "aws_kms_ciphertext" "encrypted_secure_password" {
  key_id    = aws_kms_key.password_kms.key_id
  plaintext = local.secure_password
}