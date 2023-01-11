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
  source          = "../../../modules/hub"
  name            = "${data.terraform_remote_state.init.outputs.environment}-imperva-dsf-hub"
  subnet_id       = var.subnet_id
  key_pair        = data.terraform_remote_state.init.outputs.key_pair
  sg_ingress_cidr = var.security_group_ingress_cidrs
  binaries_location = {
    s3_bucket = data.terraform_remote_state.init.outputs.s3_bucket
    s3_key    = var.dsf_install_tarball_path
  }
  web_console_admin_password                = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["web_console_admin_password"]
  ssh_key_pair_path             = data.terraform_remote_state.init.outputs.key_pair_pem_local_path
  additional_install_parameters = var.additional_parameters
}

module "sonarg1" {
  source          = "../../../modules/agentless-gw"
  name            = "${data.terraform_remote_state.init.outputs.environment}-imperva-dsf-agentless-gw1"
  subnet_id       = var.subnet_id
  key_pair        = data.terraform_remote_state.init.outputs.key_pair
  sg_ingress_cidr = concat(var.security_group_ingress_cidrs, ["${module.sonarw.public_address}/32"])
  binaries_location = {
    s3_bucket = data.terraform_remote_state.init.outputs.s3_bucket
    s3_key    = var.dsf_install_tarball_path
  }
  web_console_admin_password                = jsondecode(data.aws_secretsmanager_secret_version.dsf_passwords.secret_string)["web_console_admin_password"]
  ssh_key_pair_path             = data.terraform_remote_state.init.outputs.key_pair_pem_local_path
  additional_install_parameters = var.additional_parameters
  hub_federation_public_key             = module.sonarw.hub_federation_public_key
  sonarw_secret_name            = module.sonarw.sonarw_secret.name
  public_ip                     = true
}

module "gw_attachments" {
  source              = "../../../modules/gw-attachment"
  gw                  = module.sonarg1.public_address
  hub                 = module.sonarw.public_address
  hub_ssh_key_path    = data.terraform_remote_state.init.outputs.key_pair_pem_local_path
  installation_source = "${data.terraform_remote_state.init.outputs.s3_bucket}/${var.dsf_install_tarball_path}"
  depends_on = [
    module.sonarw,
    module.sonarg1,
  ]
}
