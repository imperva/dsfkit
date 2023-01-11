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

module "config-import-discover-dbs" {
  source            = "../../../modules/aws/config-import-discover-dbs"
  dsf_iam_role_name = data.terraform_remote_state.dsf.outputs.gw1_iam_role
  hub_ip            = data.terraform_remote_state.dsf.outputs.hub_ip
  hub_uuid          = data.terraform_remote_state.dsf.outputs.hub_uuid
  hub_display_name  = data.terraform_remote_state.dsf.outputs.hub_display_name
  gw1_uuid          = data.terraform_remote_state.dsf.outputs.gw1_uuid
  gw1_display_name  = data.terraform_remote_state.dsf.outputs.gw1_display_name
  gw1_iam_role      = data.terraform_remote_state.dsf.outputs.gw1_iam_role
  # key_pair_pem_local_path = var.key_pair_pem_local_path
  key_pair_pem_local_path = data.terraform_remote_state.init.outputs.key_pair_pem_local_path
}