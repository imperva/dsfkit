output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = try(aws_eip.dsf_instance_eip[0].public_ip, null)
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = tolist(aws_network_interface.eni.private_ips)[0]
}

output "public_dns" {
  description = "Public dns of elastic IP address of the DSF base instance"
  value       = try(aws_eip.dsf_instance_eip[0].public_dns, null)
}

output "private_dns" {
  description = "Private dns address of the DSF base instance"
  value       = aws_network_interface.eni.private_dns_name
}

output "sg_id" {
  description = "Security group on DSF base instance"
  value       = local.security_group_id
}

output "ingress_ports" {
  value = local.ingress_ports
  description = "The ingress ports of the security group on the DSF node EC2"
}

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value = local.role_arn
}

output "sonarw_public_key" {
  value = local.primary_node_sonarw_public_key
}

output "sonarw_private_key" {
  value = local.primary_node_sonarw_private_key
}

output "jsonar_uid" {
  value = random_uuid.uuid.result
}

output "display_name" {
  value = local.display_name
}

output "ssh_user" {
  value = local.ami_user
}