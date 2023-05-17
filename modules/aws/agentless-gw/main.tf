locals {
  security_groups_config = [ # https://docs.imperva.com/bundle/v4.11-sonar-installation-and-setup-guide/page/78702.htm
    {
      name  = ["ssh"]
      udp   = []
      tcp   = [22]
      cidrs = concat(var.allowed_ssh_cidrs, var.allowed_all_cidrs)
    },
    {
      name  = ["hub"]
      udp   = []
      tcp   = [22, 8443]
      cidrs = concat(var.allowed_hub_cidrs, var.allowed_all_cidrs)
    },
    {
      name  = ["agentless", "gw", "replica", "set"]
      udp   = []
      tcp   = [3030, 27117, 22]
      cidrs = concat(var.allowed_agentless_gw_cidrs, var.allowed_all_cidrs)
    }
  ]
}

resource "random_string" "gw_id" {
  length  = 8
  special = false
}

module "gw_instance" {
  source                        = "../../../modules/aws/sonar-base-instance"
  resource_type                 = "agentless-gw"
  name                          = var.friendly_name
  subnet_id                     = var.subnet_id
  security_groups_config                 = local.security_groups_config
  security_group_ids                     = var.security_group_ids
  key_pair                      = var.ssh_key_pair.ssh_public_key_name
  ec2_instance_type             = var.instance_type
  ebs_details                   = var.ebs
  ami                           = var.ami
  instance_profile_name         = var.instance_profile_name
  additional_install_parameters = var.additional_install_parameters
  web_console_admin_password    = var.web_console_admin_password
  web_console_admin_password_secret_name = var.web_console_admin_password_secret_name
  ssh_key_path                           = var.ssh_key_pair.ssh_private_key_file_path
  binaries_location                      = var.binaries_location
  hub_sonarw_public_key                  = var.hub_sonarw_public_key
  hadr_secondary_node                    = var.hadr_secondary_node
  sonarw_public_key                      = var.sonarw_public_key
  sonarw_private_key                     = var.sonarw_private_key
  proxy_info = {
    proxy_address      = var.ingress_communication_via_proxy.proxy_address
    proxy_ssh_key_path = var.ingress_communication_via_proxy.proxy_private_ssh_key_path
    proxy_ssh_user     = var.ingress_communication_via_proxy.proxy_ssh_user
  }
  skip_instance_health_verification = var.skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  use_public_ip                     = false
  attach_persistent_public_ip       = false
  internal_private_key_secret_name  = var.internal_private_key_secret_name
  internal_public_key               = var.internal_public_key
  tags = var.tags
}
