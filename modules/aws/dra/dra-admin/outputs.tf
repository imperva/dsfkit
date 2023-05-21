output "public_ip" {
  value       = try(aws_eip.dsf_instance_eip[0].public_ip, try(aws_instance.dsf_base_instance.public_ip, null))
  description = "Public elastic IP address of the DSF Admin Server instance"
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "private_ip" {
  value       = tolist(aws_network_interface.eni.private_ips)[0]
  description = "Private IP address of the DSF Admin Server instance"
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "public_dns" {
  description = "Public DNS of the elastic IP address of the DSF Admin Server instance"
  value       = try(aws_eip.dsf_instance_eip[0].public_dns, try(aws_instance.dsf_base_instance.public_dns, null))
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "private_dns" {
  description = "Private DNS of the elastic IP address of the DSF Admin Server instance"
  value       = aws_network_interface.eni.private_dns_name
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value       = local.role_arn
}

output "display_name" {
  value = aws_instance.dsf_base_instance.tags.Name
}

output "admin_analytics_registration_password_secret_arn" {
  value = aws_secretsmanager_secret.admin_analytics_registration_password_secret.arn
}

output "ssh_user" {
  value = "cbadmin"
}

output "ssh_password" {
  value = "admin"
}
