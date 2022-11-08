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
# 	  username = var.username
#     password = var.password
# 	#### Uncomment the following line, and comment out the previous to use the randomly generated password ####
#     # pasword = random_password.password
#   }
# }

# resource "aws_secretsmanager_secret" "rds_passwords" {
#   	name = "${data.terraform_remote_state.init.outputs.environment}/rds_db_passwords"
# 	#### Uncomment the following line, and comment out the previous to override the environment name defined in init ####
# 	# name = "${var.environment}/rds_passwords"
# }

# resource "aws_secretsmanager_secret_version" "rds_passwords" {
#   secret_id     = aws_secretsmanager_secret.rds_passwords.id
#   secret_string = jsonencode(local.rds_passwords_obj)
# }

module "rds-mysql-db" {
	source  = "../../modules/rds-mysql-db"
	region = data.terraform_remote_state.init.outputs.region
	# username = local.rds_passwords_obj.username
	# password = local.rds_passwords_obj.pasword	
	username = var.username
	password = var.password
	rds_subnet_ids = var.rds_subnet_ids	
	# key_pair_pem_local_path = var.key_pair_pem_local_path
	key_pair_pem_local_path = data.terraform_remote_state.init.outputs.key_pair_pem_local_path
	db_identifier = var.db_identifier
	db_name = "isbt_db"
	init_sql_file_path = "init/init_db.sql"
	security_group_ingress_cidrs = data.terraform_remote_state.dsf.outputs.security_group_ingress_cidrs
}
