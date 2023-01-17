#################################
# Generating ssh federation keys
#################################

resource "tls_private_key" "dsf_hub_ssh_federation_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  dsf_hub_ssh_public_federation_key  = !var.hadr_secondary_node ? "${chomp(tls_private_key.dsf_hub_ssh_federation_key.public_key_openssh)} produced-by-terraform" : var.hadr_main_hub_federation_public_key
  dsf_hub_ssh_private_federation_key = !var.hadr_secondary_node ? chomp(tls_private_key.dsf_hub_ssh_federation_key.private_key_pem) : var.hadr_main_hub_federation_private_key
  secret_aws_arn                     = aws_secretsmanager_secret.dsf_hub_federation_private_key.arn
  secret_aws_name                    = aws_secretsmanager_secret.dsf_hub_federation_private_key.name
}

resource "aws_secretsmanager_secret" "dsf_hub_federation_private_key" {
  name_prefix = "dsf-hub-federation-private-key"
  description = "Imperva DSF Hub sonarw private ssh key - used for remote gw federation"
}

resource "aws_secretsmanager_secret_version" "dsf_hub_federation_private_key_ver" {
  secret_id     = aws_secretsmanager_secret.dsf_hub_federation_private_key.id
  secret_string = chomp(local.dsf_hub_ssh_private_federation_key)
}
