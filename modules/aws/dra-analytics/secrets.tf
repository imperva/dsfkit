resource "aws_secretsmanager_secret" "analytics_archiver_password" {
  name_prefix = "${var.friendly_name}-analytics-archiver-password"
  description = "analytics-archiver-password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "analytics_archiver_password" {
  secret_id     = aws_secretsmanager_secret.analytics_archiver_password.id
  secret_string = var.archiver_password
}

resource "aws_secretsmanager_secret" "admin_registration_password" {
  name_prefix = "${var.friendly_name}-admin-analytics-registration-password"
  description = "admin-analytics-registration-password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "admin_registration_password" {
  secret_id     = aws_secretsmanager_secret.admin_registration_password.id
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
