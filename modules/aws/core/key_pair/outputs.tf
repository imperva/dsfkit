output "key_pair" {
  value = module.key_pair
}

output "key_pair_private_pem" {
  value     = resource.local_sensitive_file.dsf_ssh_key_file
  sensitive = true
}

output "private_key_file_path" {
  value     = resource.local_sensitive_file.dsf_ssh_key_file.filename
  sensitive = false
}