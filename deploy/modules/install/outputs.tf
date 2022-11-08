output "instance_version" {
  value = var.installation_location.s3_key
}

output "jsonar_uid" {
  value = random_uuid.uuid.result
}
