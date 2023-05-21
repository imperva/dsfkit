resource "aws_secretsmanager_secret" "admin_analytics_registration_password_secret" {
  name_prefix = "${var.friendly_name}-admin-analytics-registration-password"
  description = "DRA admin_analytics_registration_password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "admin_analytics_registration_password_secret_ver" {
  secret_id     = aws_secretsmanager_secret.admin_analytics_registration_password_secret.id
  secret_string = var.admin_analytics_registration_password
}
