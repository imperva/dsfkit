output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = module.mx.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = module.mx.private_ip
}

output "public_dns" {
  description = "Public dns of elastic IP address of the DSF base instance"
  value       = module.mx.public_dns
}

output "private_dns" {
  description = "Private dns address of the DSF base instance"
  value       = module.mx.private_dns
}

output "sg_id" {
  description = "Security group on DSF base instance"
  value       = module.mx.sg_id
}

output "ingress_ports" {
  value       = module.mx.ingress_ports
  description = "The ingress ports of the security group on the DSF node EC2"
}

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value       = module.mx.iam_role
}

output "display_name" {
  value = module.mx.display_name
}

output "ssh_user" {
  value = module.mx.ssh_user
}
