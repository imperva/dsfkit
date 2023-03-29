output "public_ip" {
  description = "Public elastic IP address of the DSF base instance"
  value       = try(aws_eip.dsf_instance_eip[0].public_ip, null)
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF base instance"
  value       = tolist(aws_network_interface.eni.private_ips)[0]
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "public_dns" {
  description = "Public dns of elastic IP address of the DSF base instance"
  value       = try(aws_eip.dsf_instance_eip[0].public_dns, null)
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "private_dns" {
  description = "Private dns address of the DSF base instance"
  value       = aws_network_interface.eni.private_dns_name
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

# output "sg_id" {
#   description = "Security group on DSF base instance"
#   value       = local.security_group_ids[0] # tbd: fix this
# }

# output "ingress_ports" {
#   value       = local.ingress_ports
#   description = "The ingress ports of the security group on the DSF node EC2"
# }

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value       = local.role_arn
}

output "display_name" {
  value = aws_instance.dsf_base_instance.tags.Name
}

output "eni_id" {
  value = aws_network_interface.eni.id
}