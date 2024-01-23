resource "aws_secretsmanager_secret" "admin_analytics_registration_password" {
  name_prefix = "${var.name}-admin-analytics-registration-password"
  description = "DRA admin registration password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "admin_analytics_registration_password" {
  secret_id     = aws_secretsmanager_secret.admin_analytics_registration_password.id
  secret_string = var.admin_registration_password
}

resource "aws_secretsmanager_secret" "admin_ssh_password" {
  name_prefix = "${var.name}-admin-ssh-password"
  description = "DRA Admin ssh password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "admin_ssh_password" {
  secret_id     = aws_secretsmanager_secret.admin_ssh_password.id
  secret_string = var.admin_ssh_password
}
