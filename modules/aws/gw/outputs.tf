output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = module.gw.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = module.gw.private_ip
}

output "public_dns" {
  description = "Public dns of elastic IP address of the DSF base instance"
  value       = module.gw.public_dns
}

output "private_dns" {
  description = "Private dns address of the DSF base instance"
  value       = module.gw.private_dns
}

# output "sg_id" {
#   description = "Security group on DSF base instance"
#   value       = module.gw.sg_id
# }

# output "ingress_ports" {
#   value       = module.gw.ingress_ports
#   description = "The ingress ports of the security group on the DSF node EC2"
# }

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value       = module.gw.iam_role
}

output "display_name" {
  value = module.gw.display_name
}

output "ssh_user" {
  value = var.ssh_user
}

output "group_id" {
  value = local.group_id
}
