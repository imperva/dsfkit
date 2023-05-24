resource "aws_secretsmanager_secret" "analytics_archiver_password" {
  name_prefix = "${var.friendly_name}-analytics-archiver-password"
  description = "analytics-archiver-password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "analytics_archiver_password" {
  secret_id     = aws_secretsmanager_secret.analytics_archiver_password.id
  secret_string = var.archiver_password
}

resource "aws_secretsmanager_secret" "admin_analytics_registration_password" {
  name_prefix = "${var.friendly_name}-admin-analytics-registration-password"
  description = "admin-analytics-registration-password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "admin_analytics_registration_password" {
  secret_id     = aws_secretsmanager_secret.admin_analytics_registration_password.id
  secret_string = var.admin_analytics_registration_password
}
