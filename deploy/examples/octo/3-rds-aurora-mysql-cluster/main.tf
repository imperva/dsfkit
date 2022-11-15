provider "aws" {
  region = data.terraform_remote_state.init.outputs.region
  #### Uncomment the following line, and comment out the previous to override the region with the local var ####
  # region = var.region
}

data "terraform_remote_state" "init" {
  backend = "local"
  config = {
    path = "${path.module}/../1-init/terraform.tfstate"
  }
}

data "terraform_remote_state" "dsf" {
  backend = "local"
  config = {
    path = "${path.module}/../2-dsf/terraform.tfstate"
  }
}

##############################################################################
######## Generating db random password and populating aws secret #############
##############################################################################
#### Uncomment the following section to generate a random password ####
# resource "random_password" "password" {
#   length = 13
#   special = true
#   override_special = "#"
# }

# locals {
#   rds_passwords_obj  = {
# 	username = var.username
#     master_pasword = var.password
# 	#### Uncomment the following line, and comment out the previous to use the randomly generated password ####
#     # master_pasword = random_password.password
#   }
# }

# resource "aws_secretsmanager_secret" "rds_passwords" {
#   	name = "${data.terraform_remote_state.init.outputs.environment}/rds_cluster_passwords"
# 	#### Uncomment the following line, and comment out the previous to override the environment name defined in init ####
# 	# name = "${var.environment}/rds_passwords"
# }

# resource "aws_secretsmanager_secret_version" "rds_passwords" {
#   secret_id     = aws_secretsmanager_secret.rds_passwords.id
#   secret_string = jsonencode(local.rds_passwords_obj)
# }

module "rds-aurora-mysql" {
  source = "../../../modules/rds-aurora-mysql"
  # username = local.rds_passwords_obj.username
  # password = local.rds_passwords_obj.master_pasword	
  username       = "imperva_user"
  password       = "Imperva123#"
  identifier     = var.cluster_identifier
  rds_subnet_ids = var.rds_subnet_ids
}