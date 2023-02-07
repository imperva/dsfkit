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
}
