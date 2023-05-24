output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = local.public_ip
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = local.private_ip
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "public_dns" {
  description = "Public DNS of the elastic IP address of the DSF base instance"
  value       = local.public_dns
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "private_dns" {
  description = "Private DNS of the elastic IP address of the DSF base instance"
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

output "ssh_user" {
  value = "cbadmin"
}
