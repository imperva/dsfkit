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

resource "tls_private_key" "sonarw_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  primary_node_sonarw_public_key  = !var.hadr_secondary_node ? "${chomp(tls_private_key.sonarw_private_key.public_key_openssh)} produced-by-terraform" : var.sonarw_public_key
  primary_node_sonarw_private_key = !var.hadr_secondary_node ? chomp(tls_private_key.sonarw_private_key.private_key_pem) : var.sonarw_private_key
  sonarw_secret_aws_arn           = aws_secretsmanager_secret.sonarw_private_key_secret.arn
  sonarw_secret_aws_name          = aws_secretsmanager_secret.sonarw_private_key_secret.name

  password_secret_aws_arn = aws_secretsmanager_secret.password_secret.arn
}

# generates a unique secret name with given prefix, e.g., imperva-dsf-8f17-hub-primary-sonarw-private-key20230205153150069800000003
resource "aws_secretsmanager_secret" "sonarw_private_key_secret" {
  name_prefix = "${var.name}-sonarw-private-key"
  description = "Imperva DSF node sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

resource "aws_secretsmanager_secret_version" "sonarw_private_key_secret_ver" {
  secret_id     = aws_secretsmanager_secret.sonarw_private_key_secret.id
  secret_string = chomp(local.primary_node_sonarw_private_key)
}

resource "aws_secretsmanager_secret" "password_secret" {
  name_prefix = "${var.name}-password"
  description = "Imperva DSF node password"
}

resource "aws_secretsmanager_secret_version" "password_ver" {
  secret_id     = aws_secretsmanager_secret.password_secret.id
  secret_string = var.web_console_admin_password
}

resource "aws_secretsmanager_secret" "access_token" {
  count       = length(local.access_tokens)
  name_prefix = "${var.name}-${local.access_tokens[count.index].name}-access-token"
  description = "Imperva EDSF ${local.access_tokens[count.index].name} access token"
}

resource "aws_secretsmanager_secret_version" "token_ver" {
  count         = length(local.access_tokens)
  secret_id     = aws_secretsmanager_secret.access_token[count.index].id
  secret_string = random_uuid.access_tokens[count.index].result
}
