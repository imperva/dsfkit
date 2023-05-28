locals {
  security_groups_config = [ # https://docs.imperva.com/bundle/v4.11-sonar-installation-and-setup-guide/page/78702.htm
    {
      name  = ["web", "console", "and", "api"]
      udp   = []
      tcp   = [8443]
      cidrs = concat(var.allowed_web_console_and_api_cidrs, var.allowed_all_cidrs)
    },
    {
      name  = ["ssh"]
      udp   = []
      tcp   = [22]
      cidrs = concat(var.allowed_ssh_cidrs, var.allowed_all_cidrs)
    },
    {
      name  = ["agentless", "gateway"]
      udp   = []
      tcp   = [8443, 61617]
      cidrs = concat(var.allowed_agentless_gw_cidrs, var.allowed_all_cidrs)
    },
    {
      name  = ["hub", "replica", "set"]
      udp   = []
      tcp   = [3030, 27117, 22, 61617]
      cidrs = concat(var.allowed_hub_cidrs, var.allowed_all_cidrs)
    }
  ]
}


module "hub_instance" {
  source                                 = "../../../modules/aws/sonar-base-instance"
  resource_type                          = "hub"
  name                                   = var.friendly_name
  subnet_id                              = var.subnet_id
  key_pair                               = var.ssh_key_pair.ssh_public_key_name
  ec2_instance_type                      = var.instance_type
  ebs_details                            = var.ebs
  ami                                    = var.ami
  security_groups_config                 = local.security_groups_config
  security_group_ids                     = var.security_group_ids
  instance_profile_name                  = var.instance_profile_name
  attach_persistent_public_ip            = var.attach_persistent_public_ip
  use_public_ip                          = var.use_public_ip
  additional_install_parameters          = var.additional_install_parameters
  web_console_admin_password             = var.web_console_admin_password
  web_console_admin_password_secret_name = var.web_console_admin_password_secret_name
  generate_access_tokens                 = var.generate_access_tokens
  ssh_key_path                           = var.ssh_key_pair.ssh_private_key_file_path
  binaries_location                      = var.binaries_location
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
  internal_private_key_secret_name  = var.internal_private_key_secret_name
  internal_public_key               = var.internal_public_key
  tags                              = var.tags
}