###################################################################################
# Generating a key pair for remote Agentless Gateway federation, HADR, etc.
# A key pair is generated only for the HADR primary nodes, and then "copied"
# to the HADR secondary nodes.
# To do that, the public key is passed to the user data of the EC2 in clear text,
# but The private key is put in AWS secret manager, and the script of the EC2 user
# data fetches it from there.
# Currently we don't delete the private key from the secret manager once the
# deployment is completed, we may need it in the future.
# In addition, both the primary and secondary nodes put the same private key
# in the key manager under a different unique name. Consider optimizing in the
# future.
#
# TODO the private key in stored unencrypted in the TF state file - handle this
# See Security notice:
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
###################################################################################

data "aws_secretsmanager_secret" "sonarw_private_key_secret_data" {
  count = var.internal_private_key_secret_name != null ? 1 : 0
  name = var.internal_private_key_secret_name
  description = "Imperva DSF node sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

data "aws_secretsmanager_secret" "password_secret_data" {
  count = var.web_console_admin_password_secret_name != null ? 1 : 0
  name = var.web_console_admin_password_secret_name
  description = "Imperva DSF node password"
}

resource "tls_private_key" "sonarw_private_key" {
  count = var.internal_private_key_secret_name == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  primary_node_sonarw_public_key  = var.internal_public_key != null ? var.internal_public_key : (!var.hadr_secondary_node ? "${chomp(tls_private_key.sonarw_private_key.public_key_openssh)} produced-by-terraform" : var.sonarw_public_key)
  primary_node_sonarw_private_key = var.internal_private_key_secret_name != null ? var.internal_private_key_secret_name : (!var.hadr_secondary_node ? chomp(tls_private_key.sonarw_private_key.private_key_pem) : var.sonarw_private_key)
  sonarw_secret_aws_arn           = var.internal_private_key_secret_name == null ? aws_secretsmanager_secret.sonarw_private_key_secret.arn : data.aws_secretsmanager_secret.sonarw_private_key_secret_data.arn
  sonarw_secret_aws_name          = var.internal_private_key_secret_name == null ? aws_secretsmanager_secret.sonarw_private_key_secret.name : data.aws_secretsmanager_secret.sonarw_private_key_secret_data.name

  password_secret_aws_arn = var.web_console_admin_password_secret_name == null ? aws_secretsmanager_secret.password_secret.arn : data.aws_secretsmanager_secret.password_secret_data.arn
}

# generates a unique secret name with given prefix, e.g., imperva-dsf-8f17-hub-primary-sonarw-private-key20230205153150069800000003
resource "aws_secretsmanager_secret" "sonarw_private_key_secret" {
  count = var.internal_private_key_secret_name == null ? 1 : 0
  name_prefix = "${var.name}-sonarw-private-key"
  description = "Imperva DSF node sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

resource "aws_secretsmanager_secret_version" "sonarw_private_key_secret_ver" {
  count = var.internal_private_key_secret_name == null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.sonarw_private_key_secret.id
  secret_string = chomp(local.primary_node_sonarw_private_key)
}

resource "aws_secretsmanager_secret" "password_secret" {
  count = var.web_console_admin_password_secret_name == null ? 1 : 0
  name_prefix = "${var.name}-password"
  description = "Imperva DSF node password"
}

resource "aws_secretsmanager_secret_version" "password_ver" {
  count = var.web_console_admin_password_secret_name == null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.password_secret.id
  secret_string = var.web_console_admin_password
}

resource "aws_secretsmanager_secret" "access_token" {
  count       = 0
  name_prefix = "${var.name}-${local.access_tokens[count.index].name}-access-token"
  description = "Imperva EDSF ${local.access_tokens[count.index].name} access token"
}

resource "aws_secretsmanager_secret_version" "token_ver" {
  count         = 0
  secret_id     = aws_secretsmanager_secret.access_token[count.index].id
  secret_string = random_uuid.access_tokens[count.index].result
}
