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
#### Uncomment the following section to generate a random master_password ####
# resource "random_password" "master_password" {
#   length = 13
#   special = true
#   override_special = "#"
# }

# locals {
#   rds_passwords_obj  = {
# 	master_username = var.master_username
#     master_pasword = var.master_password
# 	#### Uncomment the following line, and comment out the previous to use the randomly generated master_password ####
#     # master_pasword = random_password.master_password
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
	source  = "../../modules/rds-aurora-mysql"
	region = data.terraform_remote_state.init.outputs.region
	# master_username = local.rds_passwords_obj.master_username
	# master_password = local.rds_passwords_obj.master_pasword	
	master_username = "imperva_user"
	master_password = "Imperva123#"
	cluster_identifier = var.cluster_identifier
	rds_subnet_ids = var.rds_subnet_ids	
	# key_pair_pem_local_path = var.key_pair_pem_local_path
	key_pair_pem_local_path = data.terraform_remote_state.init.outputs.key_pair_pem_local_path
}