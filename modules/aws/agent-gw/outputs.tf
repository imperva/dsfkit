output "public_ip" {
  description = "Public elastic IP address of the DSF instance"
  value       = module.agent_gw.public_ip
  depends_on = [
    module.agent_gw.ready
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF instance"
  value       = module.agent_gw.private_ip
  depends_on = [
    module.agent_gw.ready
  ]
}

output "public_dns" {
  description = "Public dns of elastic IP address of the DSF instance"
  value       = module.agent_gw.public_dns
  depends_on = [
    module.agent_gw.ready
  ]
}

output "private_dns" {
  description = "Private dns address of the DSF instance"
  value       = module.agent_gw.private_dns
  depends_on = [
    module.agent_gw.ready
  ]
}

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value       = module.agent_gw.iam_role
}

output "display_name" {
  description = "Display name"
  value       = module.agent_gw.display_name
}

output "ssh_user" {
  description = "Ssh username"
  value       = var.ssh_user
}

output "instance_id" {
  value = module.agent_gw.instance_id
}

output "gateway_group_name" {
  value = local.gateway_group_name
}

output "large_scale_mode" {
  value = var.large_scale_mode
}