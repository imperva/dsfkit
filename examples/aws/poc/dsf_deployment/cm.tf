locals {
  ciphertrust_manager_count = local.enable_ciphertrust ? var.ciphertrust_manager_count : 0
  ciphertrust_cidr_list = [data.aws_subnet.ciphertrust_manager.cidr_block]
  ciphertrust_manager_web_console_username = "admin"
}

module "ciphertrust_manager" {
  # TODO sivan - change module name to ciphertrust manager
  source  = "../../../../modules/aws/ciphertrust-manager"
  #   source  = "imperva/dsf-ciphertrust-manager/aws"
  #   version = "1.7.17" # latest release tag
  count   = local.ciphertrust_manager_count
  ami  = var.ciphertrust_manager_ami_id == null ? null : {
    id               = var.ciphertrust_manager_ami_id
    name_regex       = null
    product_code     = null
    owner_account_id = null
  }
  friendly_name               = join("-", [local.deployment_name_salted, "ciphertrust", "manager", count.index])
  ebs                         = var.ciphertrust_manager_ebs_details
  subnet_id                   = local.ciphertrust_manager_subnet_id
  attach_persistent_public_ip = true
  key_pair                          = module.key_pair.key_pair.key_pair_name
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_ssh_cidrs                 = concat(local.workstation_cidr, var.allowed_ssh_cidrs)
  allowed_cluster_nodes_cidrs       = [data.aws_subnet.ciphertrust_manager.cidr_block]
  allowed_ddc_agents_cidrs          = [data.aws_subnet.cte_ddc_agent.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

provider "ciphertrust" {
  address  = local.ciphertrust_manager_count > 0 ? "https://${module.ciphertrust_manager[0].public_ip}" : null
  username = local.ciphertrust_manager_web_console_username
  password = local.ciphertrust_manager_password
  // destroy cluster can take almost a minute so give us a bit of a buffer
  rest_api_timeout = 720
}

resource "ciphertrust_trial_license" "trial_license" {
  count = local.ciphertrust_manager_count > 0 ? 1 : 0
  flag = "activate"
}

module "ciphertrust_manager_cluster_setup" {
  source  = "../../../../modules/null/ciphertrust-manager-cluster-setup"
  #   source  = "imperva/dsf-ciphertrust-manager-cluster-setup/aws"
  #   version = "1.7.17" # latest release tag
  count   = local.ciphertrust_manager_count > 1 ? 1 : 0
  nodes = [
    for i in range(length(module.ciphertrust_manager)) : {
      host = module.ciphertrust_manager[i].private_ip
      public_address    = coalesce(module.ciphertrust_manager[i].public_ip, module.ciphertrust_manager[i].private_ip)
    }
  ]
  credentials = {
    user     = local.ciphertrust_manager_web_console_username
    password = local.ciphertrust_manager_password
  }
  ddc_node_setup = {
    enabled = true
    node_address = coalesce(module.ciphertrust_manager[0].public_ip, module.ciphertrust_manager[0].private_ip)
  }
  depends_on = [
    module.ciphertrust_manager
  ]
}