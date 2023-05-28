module "key_pair" {
  source             = "terraform-aws-modules/key-pair/aws"
  key_name_prefix    = var.key_name_prefix
  create_private_key = var.create_private_key
  tags               = var.tags
}

resource "local_sensitive_file" "dsf_ssh_key_file" {
  content         = module.key_pair.private_key_pem
  file_permission = 600
  filename        = var.private_key_pem_filename
}
