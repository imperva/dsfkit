provider "aws" {
	region = data.terraform_remote_state.init.outputs.region
}

data "terraform_remote_state" "init" {
	backend = "local"
	config = {
		path = "${path.module}/../1-init/terraform.tfstate"
	}
}

data "aws_secretsmanager_secret" "dsf_passwords" {
  name = data.terraform_remote_state.init.outputs.dsf_passwords_secret_name
}

data "aws_secretsmanager_secret_version" "dsf_passwords" {
  secret_id = data.aws_secretsmanager_secret.dsf_passwords.id
}

module "sonarw" {
	source  = "../../modules/sonarw"
	region = data.terraform_remote_state.init.outputs.region
	name = "${data.terraform_remote_state.init.outputs.environment}-imperva-dsf-hub"
	subnet_id = var.subnet_id
	key_pair = data.terraform_remote_state.init.outputs.key_pair
	key_pair_pem_local_path = data.terraform_remote_state.init.outputs.key_pair_pem_local_path
	s3_bucket = data.terraform_remote_state.init.outputs.s3_bucket
	ec2_instance_type = var.ec2_instance_type
	aws_ami_name = var.aws_ami_name
	ebs_disk_size = 500
	dsf_version = var.dsf_version
	dsf_install_tarball_path = var.dsf_install_tarball_path
	security_group_ingress_cidrs = var.security_group_ingress_cidrs
	dsf_hub_public_key_name = data.terraform_remote_state.init.outputs.dsf_hub_sonarw_public_ssh_key_name
	dsf_hub_private_key_name = data.terraform_remote_state.init.outputs.dsf_hub_sonarw_private_ssh_key_name
	dsf_gateway_public_authorized_keys = [
		data.terraform_remote_state.init.outputs.dsf_hub_sonarw_public_ssh_key_name,
		data.terraform_remote_state.init.outputs.dsf_gateway_sonarw_public_ssh_key_name
	]
	dsf_iam_profile_name = data.terraform_remote_state.init.outputs.dsf_iam_profile_name
	admin_password = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["admin_password"]
	secadmin_password = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["secadmin_password"]
	sonarg_pasword = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["sonarg_pasword"]
	sonargd_pasword = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["sonargd_pasword"]
}

module "sonarg1" {
	source  = "../../modules/sonarg"
	depends_on = [
	  module.sonarw.private_ip
	]
	region = data.terraform_remote_state.init.outputs.region
	name = "${data.terraform_remote_state.init.outputs.environment}-imperva-dsf-agentless-gw1"
	subnet_id = var.subnet_id
	key_pair = data.terraform_remote_state.init.outputs.key_pair
	key_pair_pem_local_path = data.terraform_remote_state.init.outputs.key_pair_pem_local_path
	s3_bucket = data.terraform_remote_state.init.outputs.s3_bucket
	ec2_instance_type = var.ec2_instance_type
	aws_ami_name = var.aws_ami_name
	ebs_disk_size = 150
	dsf_version = var.dsf_version
	dsf_install_tarball_path = var.dsf_install_tarball_path
	security_group_ingress_cidrs = var.security_group_ingress_cidrs
	dsf_gateway_public_key_name = data.terraform_remote_state.init.outputs.dsf_gateway_sonarw_public_ssh_key_name
	dsf_gateway_private_key_name = data.terraform_remote_state.init.outputs.dsf_gateway_sonarw_private_ssh_key_name
	dsf_hub_public_authorized_key = data.terraform_remote_state.init.outputs.dsf_hub_sonarw_public_ssh_key_name
	dsf_iam_profile_name = data.terraform_remote_state.init.outputs.dsf_iam_profile_name
	admin_password = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["admin_password"]
	secadmin_password = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["secadmin_password"]
	sonarg_pasword = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["sonarg_pasword"]
	sonargd_pasword = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["sonargd_pasword"]
	hub_ip = module.sonarw.private_ip
}