output "public_ip" {
  description = "Public Elastic IP address of the DSF base instance"
  value       = aws_eip.dsf_instance_eip.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = aws_instance.dsf_base_instance.private_ip
}