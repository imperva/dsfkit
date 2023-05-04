output "analytics_public_ip" {
  value = aws_instance.dra_analytics.public_ip
}

output "analytics_private_ip" {
  value = aws_instance.dra_analytics.private_ip
}

output "archiver_user" {
  value = var.archiver_user
}

output "archiver_password" {
  sensitive = true
  value = var.archiver_password
}