resource "aws_secretsmanager_secret" "analytics_archiver_password" {
  name_prefix = "${var.name}-analytics-archiver-password"
  description = "analytics-archiver-password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "analytics_archiver_password" {
  secret_id     = aws_secretsmanager_secret.analytics_archiver_password.id
  secret_string = var.archiver_password
}

resource "aws_secretsmanager_secret" "admin_registration_password" {
  name_prefix = "${var.name}-admin-analytics-registration-password"
  description = "admin-analytics-registration-password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "admin_registration_password" {
  secret_id     = aws_secretsmanager_secret.admin_registration_password.id
  secret_string = var.admin_registration_password
}

resource "aws_secretsmanager_secret" "analytics_ssh_password" {
  name_prefix = "${var.name}-analytics-ssh-password"
  description = "DRA Analytics ssh password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "analytics_ssh_password" {
  secret_id     = aws_secretsmanager_secret.analytics_ssh_password.id
  secret_string = var.analytics_ssh_password
}
