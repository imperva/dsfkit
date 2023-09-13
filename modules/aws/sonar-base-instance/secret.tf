###################################################################################
# Generating a key pair for remote Agentless Gateway federation, HADR, etc.
# A key pair is generated only for the HADR main nodes, and then "copied"
# to the HADR DR nodes.
# To do that, the public key is passed to the user data of the EC2 in clear text,
# but The private key is put in AWS secret manager, and the script of the EC2 user
# data fetches it from there.
# Currently we don't delete the private key from the secret manager once the
# deployment is completed, we may need it in the future.
# In addition, both the main and DR nodes put the same private key
# in the key manager under a different unique name. Consider optimizing in the
# future.
#
# TODO the private key is stored unencrypted in the TF state file - handle this
# See Security notice:
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
###################################################################################

data "aws_secretsmanager_secret" "sonarw_private_key_secret_data" {
  count = var.sonarw_private_key_secret_name != null ? 1 : 0
  name  = var.sonarw_private_key_secret_name
}

data "aws_secretsmanager_secret" "password_secret_data" {
  count = var.password_secret_name != null ? 1 : 0
  name  = var.password_secret_name
}

resource "tls_private_key" "sonarw_private_key" {
  count     = var.sonarw_private_key_secret_name == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  main_node_sonarw_public_key  = var.sonarw_public_key_content != null ? var.sonarw_public_key_content : (!var.hadr_dr_node ? "${chomp(tls_private_key.sonarw_private_key[0].public_key_openssh)} produced-by-terraform" : var.main_node_sonarw_public_key)
  main_node_sonarw_private_key = var.sonarw_private_key_secret_name != null ? var.sonarw_private_key_secret_name : (!var.hadr_dr_node ? chomp(tls_private_key.sonarw_private_key[0].private_key_pem) : var.main_node_sonarw_private_key)
  sonarw_secret_aws_arn           = var.sonarw_private_key_secret_name == null ? aws_secretsmanager_secret.sonarw_private_key_secret[0].arn : data.aws_secretsmanager_secret.sonarw_private_key_secret_data[0].arn
  sonarw_secret_aws_name          = var.sonarw_private_key_secret_name == null ? aws_secretsmanager_secret.sonarw_private_key_secret[0].name : data.aws_secretsmanager_secret.sonarw_private_key_secret_data[0].name

  password_secret_aws_arn = var.password_secret_name == null ? aws_secretsmanager_secret.password_secret[0].arn : data.aws_secretsmanager_secret.password_secret_data[0].arn
  password_secret_name    = var.password_secret_name == null ? aws_secretsmanager_secret.password_secret[0].name : var.password_secret_name

  should_create_sonarw_private_key_in_secrets_manager   = var.sonarw_private_key_secret_name == null
  should_create_password_in_secrets_manager = var.password_secret_name == null
  
  secret_names = [for v in aws_secretsmanager_secret.access_tokens: v.name]
}

# generates a unique secret name with given prefix, e.g., imperva-dsf-8f17-hub-main-sonarw-private-key20230205153150069800000003
resource "aws_secretsmanager_secret" "sonarw_private_key_secret" {
  count       = local.should_create_sonarw_private_key_in_secrets_manager == true ? 1 : 0
  name_prefix = "${var.name}-sonarw-private-key"
  description = "Imperva DSF node sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "sonarw_private_key_secret_ver" {
  count         = local.should_create_sonarw_private_key_in_secrets_manager == true ? 1 : 0
  secret_id     = aws_secretsmanager_secret.sonarw_private_key_secret[0].id
  secret_string = chomp(local.main_node_sonarw_private_key)
}

resource "aws_secretsmanager_secret" "password_secret" {
  count       = local.should_create_password_in_secrets_manager == true ? 1 : 0
  name_prefix = "${var.name}-password"
  description = "Imperva DSF node password"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "password_ver" {
  count         = local.should_create_password_in_secrets_manager == true ? 1 : 0
  secret_id     = aws_secretsmanager_secret.password_secret[0].id
  secret_string = var.password
}

resource "aws_secretsmanager_secret" "access_tokens" {
  count       = length(local.access_tokens)
  name_prefix = "${var.name}-${local.access_tokens[count.index].name}-access-token"
  description = "Imperva EDSF ${local.access_tokens[count.index].name} access token"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "token_ver" {
  count         = length(local.access_tokens)
  secret_id     = aws_secretsmanager_secret.access_tokens[count.index].id
  secret_string = random_uuid.access_tokens[count.index].result
}
