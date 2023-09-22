locals {
  security_groups_config = [ # https://docs.imperva.com/bundle/v4.11-sonar-installation-and-setup-guide/page/78702.htm
    {
      name            = ["web", "console", "and", "api"]
      internet_access = false
      udp             = []
      tcp             = [8443]
      cidrs           = concat(var.allowed_web_console_and_api_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["other"]
      internet_access = true
      udp             = []
      tcp             = [22]
      cidrs           = concat(var.allowed_ssh_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["agentless", "gateway"]
      internet_access = false
      udp             = []
      tcp             = [8443, 61617]
      cidrs           = concat(var.allowed_agentless_gw_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["hub", "replica", "set"]
      internet_access = false
      udp             = []
      tcp             = [22, 3030, 27117, 61617]
      cidrs           = concat(var.allowed_hub_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["dra", "admin"]
      internet_access = false
      udp             = []
      tcp             = [10674, 8443]
      cidrs           = concat(var.allowed_dra_admin_cidrs, var.allowed_all_cidrs)
    }
  ]
}

resource "tls_private_key" "sonarw_private_key" {
  count     = var.sonarw_private_key_secret_name == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "hub_instance" {
  source                            = "../../../modules/aws/sonar-base-instance"
  resource_type                     = "hub"
  name                              = var.friendly_name
  subnet_id                         = var.subnet_id
  key_pair                          = var.ssh_key_pair.ssh_public_key_name
  ec2_instance_type                 = var.instance_type
  ebs_details                       = var.ebs
  ami                               = var.ami
  security_groups_config            = local.security_groups_config
  security_group_ids                = var.security_group_ids
  instance_profile_name             = var.instance_profile_name
  attach_persistent_public_ip       = var.attach_persistent_public_ip
  use_public_ip                     = var.use_public_ip
  additional_install_parameters     = var.additional_install_parameters
  admin_password                    = var.admin_password
  secadmin_password                 = var.secadmin_password
  sonarg_password                   = var.sonarg_password
  sonargd_password                  = var.sonargd_password
  admin_password_secret_name        = var.admin_password_secret_name
  secadmin_password_secret_name     = var.secadmin_password_secret_name
  sonarg_password_secret_name       = var.sonarg_password_secret_name
  sonargd_password_secret_name      = var.sonargd_password_secret_name
  generate_access_tokens            = var.generate_access_tokens
  ssh_key_path                      = var.ssh_key_pair.ssh_private_key_file_path
  binaries_location                 = var.binaries_location
  hadr_dr_node                      = var.hadr_dr_node
  main_node_sonarw_public_key       = var.main_node_sonarw_public_key
  main_node_sonarw_private_key      = var.main_node_sonarw_private_key
  proxy_info                        = var.hub_proxy_info
  skip_instance_health_verification = var.skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_private_key_secret_name
  sonarw_public_key_content         = var.sonarw_public_key_content
  volume_attachment_device_name     = var.volume_attachment_device_name
  tags                              = var.tags
}