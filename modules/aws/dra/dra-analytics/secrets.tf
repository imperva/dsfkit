resource "aws_secretsmanager_secret" "analytics_archiver_password_secret" {
  name_prefix = "${var.friendly_name}-analytics-archiver-password"
  description = "analytics-archiver-passwordd"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "analytics_archiver_password_secret_ver" {
  secret_id     = aws_secretsmanager_secret.analytics_archiver_password_secret.id
  secret_string = var.archiver_password
}
