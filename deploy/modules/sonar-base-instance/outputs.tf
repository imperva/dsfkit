output "public_address" {
  description = "Public Elastic IP address of the DSF base instance"
  value       = can(aws_eip.dsf_instance_eip[0].public_ip) ? aws_eip.dsf_instance_eip[0].public_ip : null
}

output "private_address" {
  description = "Private IP address of the DSF base instance"
  value       = tolist(aws_network_interface.eni.private_ips)[0]
}

output "sg_id" {
  description = "Security group on DSF base instance"
  value       = aws_security_group.dsf_base_sg.id
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