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

output "jsonar_uid" {
  value = random_uuid.uuid.result
}

output "display_name" {
  value = local.display_name
}

output "ssh_user" {
  value = local.ami_user
}