output "public_ip" {
  description = "Public elastic IP address of the DSF mx instance"
  value       = module.mx.public_ip
  depends_on = [
    module.mx.ready
  ]
}

output "private_ip" {
  description = "Private IP address of the DSF mx instance"
  value       = module.mx.private_ip
  depends_on = [
    module.mx.ready
  ]
}

output "public_dns" {
  description = "Public dns of elastic IP address of the DSF mx instance"
  value       = module.mx.public_dns
  depends_on = [
    module.mx.ready
  ]
}

output "private_dns" {
  description = "Private dns address of the DSF mx instance"
  value       = module.mx.private_dns
  depends_on = [
    module.mx.ready
  ]
}

output "iam_role" {
  description = "IAM Role ARN of the DSF node"
  value       = module.mx.iam_role
}

output "display_name" {
  value = module.mx.display_name
}

output "ssh_user" {
  value = var.ssh_user
}

output "instance_id" {
  value = module.mx.instance_id
}

output "configuration" {
  value = {
    default_site         = replace(local.site, "%20", " ")
    default_server_group = local.server_group
  }
  depends_on = [
    null_resource.import_configuration
  ]
}
