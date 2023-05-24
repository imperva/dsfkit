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

output "ready" {
  description = <<-EOF
    Indicates when module is "ready"
  EOF
  value       = "ready"
  depends_on = [
    null_resource.readiness
  ]
}