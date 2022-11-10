output "salt" {
  value = resource.random_id.salt.hex
}

output "my_ip" {
  value = data.local_file.myip_file.content
}

output "now" {
  value = resource.time_static.current_time.id
}

output "random_password" {
  value = resource.random_password.pass.result
}

output "key_pair" {
  value = module.key_pair.key_pair
}

output "key_pair_private_pem" {
  value = module.key_pair.key_pair_private_pem
}

output "tags" {
  value = {
    terraform_workspace                = terraform.workspace
    vendor                             = "Imperva"
    product                            = "EDSF"
    terraform                          = "true"
    environment                        = "demo"
    creation_timestamp                 =  resource.time_static.current_time.id
  }
}