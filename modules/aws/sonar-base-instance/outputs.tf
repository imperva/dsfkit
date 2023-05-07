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

output "sonarw_public_key" {
  value = local.primary_node_sonarw_public_key
}

output "sonarw_private_key" {
  value = local.primary_node_sonarw_private_key
}

output "jsonar_uid" {
  value = random_uuid.jsonar_uuid.result
}

output "display_name" {
  value = local.display_name
}

output "ssh_user" {
  value = local.ami_username
}

output "instance_id" {
  value = aws_instance.dsf_base_instance.id
}

output "access_tokens" {
  value = { for val in local.access_tokens_array : val.name => {
    name        = val.name
    token       = val.token
    secret_name = val.secret_name
    }
  }
  sensitive = true
}