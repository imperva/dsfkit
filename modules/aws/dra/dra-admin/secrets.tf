resource "aws_secretsmanager_secret" "admin_analytics_registration_password" {
  name_prefix = "${var.friendly_name}-admin-analytics-registration-password"
  description = "DRA admin_registration_password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "admin_analytics_registration_password" {
  secret_id     = aws_secretsmanager_secret.admin_analytics_registration_password.id
  secret_string = var.admin_registration_password
}

resource "aws_secretsmanager_secret" "admin_password" {
  name_prefix = "${var.friendly_name}-admin-password"
  description = "DRA admin_registration_password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "admin_password" {
  secret_id     = aws_secretsmanager_secret.admin_password.id
  secret_string = var.admin_password
}
