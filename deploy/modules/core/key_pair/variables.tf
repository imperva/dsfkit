#   source             = "terraform-aws-modules/key-pair/aws"
#   key_name_prefix    = "imperva-dsf-"
#   create_private_key = true
# }

# resource "local_sensitive_file" "dsf_ssh_key_file" {
#   content         = module.key_pair.key_pair_private_pem
#   file_permission = 400
#   filename        = "ssh_keys/dsf_ssh_key-${terraform.workspace}"

variable "key_name_prefix" {
  type = string
}

variable "create_private_key" {
  type = bool
  default = true
}

variable "private_key_pem_filename" {
  type = string
}