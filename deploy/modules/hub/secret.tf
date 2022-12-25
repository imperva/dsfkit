#################################
# Generating ssh federation keys
#################################

resource "tls_private_key" "dsf_hub_ssh_federation_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  dsf_hub_ssh_federation_key = !var.hadr_secondary_node ? "${chomp(resource.tls_private_key.dsf_hub_ssh_federation_key.public_key_openssh)} produced-by-terraform" : var.hadr_main_hub_federation_public_key
  created_secret_aws_arn     = length(resource.aws_secretsmanager_secret.dsf_hub_federation_private_key) > 0 ? resource.aws_secretsmanager_secret.dsf_hub_federation_private_key[0].arn : ""
  created_secret_aws_name    = length(resource.aws_secretsmanager_secret.dsf_hub_federation_private_key) > 0 ? resource.aws_secretsmanager_secret.dsf_hub_federation_private_key[0].name : ""
  secret_aws_arn             = !var.hadr_secondary_node ? local.created_secret_aws_arn : var.hadr_main_hub_sonarw_secret.arn
  secret_aws_name            = !var.hadr_secondary_node ? local.created_secret_aws_name : var.hadr_main_hub_sonarw_secret.name
}

resource "aws_secretsmanager_secret" "dsf_hub_federation_public_key" {
  count       = !var.hadr_secondary_node ? 1 : 0
  name_prefix = "dsf-hub-federation-public-key"
  description = "Imperva DSF Hub sonarw public ssh key - used for remote gw federation"
}

resource "aws_secretsmanager_secret_version" "dsf_hub_federation_public_key_ver" {
  count         = !var.hadr_secondary_node ? 1 : 0
  secret_id     = aws_secretsmanager_secret.dsf_hub_federation_public_key[0].id
  secret_string = chomp(local.dsf_hub_ssh_federation_key)
}

resource "aws_secretsmanager_secret" "dsf_hub_federation_private_key" {
  count       = !var.hadr_secondary_node ? 1 : 0
  name_prefix = "dsf-hub-federation-private-key"
  description = "Imperva DSF Hub sonarw private ssh key - used for remote gw federation"
}

resource "aws_secretsmanager_secret_version" "dsf_hub_federation_private_key_ver" {
  count         = !var.hadr_secondary_node ? 1 : 0
  secret_id     = aws_secretsmanager_secret.dsf_hub_federation_private_key[0].id
  secret_string = resource.tls_private_key.dsf_hub_ssh_federation_key.private_key_pem
}
