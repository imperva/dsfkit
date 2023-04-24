output "url" {
  value = "https://${aws_instance.dra_admin.public_ip}:8443"
}

output "public_ip" {
  value = aws_instance.dra_admin.public_ip
}

output "private_ip" {
  value = aws_instance.dra_admin.private_ip
}

output "admin_analytics_registration_password_secret_arn" {
  value = aws_secretsmanager_secret.admin_analytics_registration_password_secret.arn
}
