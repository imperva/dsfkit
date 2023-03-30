output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = module.agent_gw.public_ip
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = module.agent_gw.private_ip
}

output "public_dns" {
  description = "Public dns of elastic IP address of the DSF base instance"
  value       = module.agent_gw.public_dns
}

output "private_dns" {
  description = "Private dns address of the DSF base instance"
  value       = module.agent_gw.private_dns
}

# output "sg_id" {
#   description = "Security group on DSF base instance"
#   value       = module.agent_gw.sg_id
# }

# output "ingress_ports" {
#   value       = module.agent_gw.ingress_ports
#   description = "The ingress ports of the security group on the DSF node EC2"
# }

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value       = module.agent_gw.iam_role
}

output "display_name" {
  value = module.agent_gw.display_name
}

output "ssh_user" {
  value = var.ssh_user
}

output "group_id" {
  value = local.group_id
}

output "instance_id" {
  value = module.agent_gw.instance_id
}
