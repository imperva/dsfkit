locals {
  ciphertrust_manager_count = var.enable_ciphertrust ? var.ciphertrust_manager_count : 0
  ciphertrust_cidr_list = [data.aws_subnet.ciphertrust.cidr_block]
  ciphertrust_web_console_username = "admin"
}

module "ciphertrust_manager" {
  source  = "../../../../modules/aws/ciphertrust"
#   source  = "imperva/dsf-ciphertrust/aws"
#   version = "1.7.17" # latest release tag
  count   = local.ciphertrust_manager_count
  ami_id  = var.ciphertrust_ami_id
  friendly_name               = join("-", [local.deployment_name_salted, "ciphertrust", "manager", count.index])
  ebs                         = var.ciphertrust_ebs_details
  subnet_id                   = local.ciphertrust_subnet_id
  attach_persistent_public_ip = true
  key_pair                          = module.key_pair.key_pair.key_pair_name
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_ssh_cidrs                 = concat(local.workstation_cidr, var.allowed_ssh_cidrs)
  allowed_cluster_nodes_cidrs       = [data.aws_subnet.ciphertrust.cidr_block]
  allowed_ddc_agents_cidrs          = []
  allowed_all_cidrs                 = local.workstation_cidr
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

provider "ciphertrust" {
  address  =  var.enable_ciphertrust? "https://${module.ciphertrust_manager[0].public_ip}" : null
  username = local.ciphertrust_web_console_username
  password = local.ciphertrust_password
  // destroy cluster can take almost a minute so give us a bit of a buffer
  rest_api_timeout = 720
}

resource "ciphertrust_trial_license" "trial_license" {
  count = var.enable_ciphertrust ? 1 : 0
  flag = "activate"
}

module "ciphertrust_cluster" {
  source  = "../../../../modules/null/ciphertrust_cluster"
  #   source  = "imperva/dsf-ciphertrust-cluster/aws"
  #   version = "1.7.17" # latest release tag
  count   = local.ciphertrust_manager_count > 1 ? 1 : 0
  ciphertrust_instances = [
    for i in range(length(module.ciphertrust_manager)) : {
      host = module.ciphertrust_manager[i].private_ip
      public_address    = coalesce(module.ciphertrust_manager[i].public_ip, module.ciphertrust_manager[i].private_ip)
    }
  ]
  cm_details = {
    user     = local.ciphertrust_web_console_username
    password = local.ciphertrust_password
  }
  ddc_node_setup = {
    enabled = true
    node_address = coalesce(module.ciphertrust_manager[0].public_ip, module.ciphertrust_manager[0].private_ip)
  }
  depends_on = [
    module.ciphertrust_manager
  ]
}