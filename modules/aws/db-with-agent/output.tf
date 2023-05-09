output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_network_interface.eni.private_ip
}

output "private_dns" {
  description = "Private dns address of the instance"
  value       = aws_network_interface.eni.private_dns_name
}

output "display_name" {
  value = aws_instance.agent.tags["Name"]
}

output "ssh_user" {
  value = local.ami_ssh_user
}

output "instance_id" {
  value = aws_instance.agent.id
}

output "db_type" {
  value = local.db_type
}

output "os_type" {
  value = local.os_type
}
