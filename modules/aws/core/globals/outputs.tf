output "salt" {
  value = resource.random_id.salt.hex
}

output "my_ip" {
  value = try(trimspace(data.http.workstation_public_ip.response_body), null)
}

output "now" {
  value = resource.time_static.current_time.id
}

output "random_password" {
  value = resource.random_password.pass.result
}

output "current_user_arn" {
  value = data.aws_caller_identity.current.arn
}

output "current_user_name" {
  value = split("/", data.aws_caller_identity.current.arn)[1] // arn:aws:iam::xxxxxxxxx:user/name
}

output "availability_zones" {
  value = sort(data.aws_availability_zones.available.names)
}

output "region" {
  value = data.aws_region.current.name
}

output "tags" {
  value = {
    terraform_workspace = terraform.workspace
    vendor              = "Imperva"
    product             = "DSF"
    terraform           = "true"
    creation_timestamp  = resource.time_static.current_time.id
  }
}

output "tarball_location" {
  value = {
    s3_bucket = var.installation_s3_bucket.bucket
    s3_region = var.installation_s3_bucket.region
    s3_key    = local.sonar_installation_s3_key
    version   = local.sonar_s3_object_version
  }
}

output "dam_agent_installation_location" {
  value = {
    s3_bucket = var.installation_s3_bucket.bucket
    s3_region = var.installation_s3_bucket.region
    s3_prefix = local.dam_agent_installation_s3_prefix
    s3_object = null
  }
}

output "dra_version" {
  value = local.dra_version
}

output "sonar_supported_versions" {
  description = "Sonar versions which are supported by at least one module"
  value       = local.sonar_supported_versions
}

output "sonar_fully_supported_versions" {
  description = "Sonar versions which are supported in by all modules"
  value       = local.sonar_fully_supported_versions
}

output "dra_supported_versions" {
  value = local.dra_supported_versions
}