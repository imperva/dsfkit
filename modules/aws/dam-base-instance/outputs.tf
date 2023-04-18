output "public_ip" {
  description = "Public elastic IP address of the DSF DAM instance"
  value       = try(aws_eip.dsf_instance_eip[0].public_ip, null)
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF DAM instance"
  value       = tolist(aws_network_interface.eni.private_ips)[0]
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "public_dns" {
  description = "Public DNS of the elastic IP address of the DSF DAM instance"
  value       = try(aws_eip.dsf_instance_eip[0].public_dns, null)
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

output "private_dns" {
  description = "Private DNS of the elastic IP address of the DSF DAM instance"
  value       = aws_network_interface.eni.private_dns_name
  depends_on = [
    aws_eip_association.eip_assoc
  ]
}

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

output "instance_id" {
  value = aws_instance.dsf_base_instance.id
}

output "ready" {
  description = <<-EOF
    Indicates when module is "ready"
  EOF
  value       = "ready"
  depends_on = [
    null_resource.readiness
  ]
}