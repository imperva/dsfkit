terraform {
  required_version = ">= 0.12.8"
}

provider "aws" {
  region = var.region
}

#################################
# Generating system passwords
#################################

# Uncomment this section to use randomly generated passwords
# /* Populate AWS secrets */
# resource "random_password" "admin_password" {
#   length = 13
#   special = true
#   override_special = "#"
# }

# /* Populate AWS secrets */
# resource "random_password" "secadmin_password" {
#   length = 13
#   special = true
#   override_special = "#"
# }

# /* Populate AWS secrets */
# resource "random_password" "sonarg_pasword" {
#   length = 13
#   special = true
#   override_special = "#"
# }

# /* Populate AWS secrets */
# resource "random_password" "sonargd_pasword" {
#   length = 13
#   special = true
#   override_special = "#"
# }

locals {
  # Uncomment this section to use randomly generated passwords instead of the pre-defined passwords listedbelow
  # dsf_passwords_obj  = {
  #   admin_password = random_password.admin_password.result
  #   secadmin_password = random_password.secadmin_password.result
  #   sonarg_pasword = random_password.sonarg_pasword.result
  #   sonargd_pasword = random_password.sonargd_pasword.result
  # }
  dsf_passwords_obj  = {
    admin_password = var.default_password
    secadmin_password = var.default_password
    sonarg_pasword = var.default_password
    sonargd_pasword = var.default_password
  }
}

resource "aws_secretsmanager_secret" "dsf_passwords" {
  name = "${var.environment}/dsf_passwords"
}

resource "aws_secretsmanager_secret_version" "dsf_passwords" {
  secret_id     = aws_secretsmanager_secret.dsf_passwords.id
  secret_string = jsonencode(local.dsf_passwords_obj)
}
