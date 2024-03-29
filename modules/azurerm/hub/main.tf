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

module "hub_instance" {
  source                            = "../../../modules/azurerm/sonar-base-instance"
  resource_type                     = "hub"
  resource_group                    = var.resource_group
  name                              = var.friendly_name
  subnet_id                         = var.subnet_id
  public_ssh_key                    = var.ssh_key.ssh_public_key
  instance_size                     = var.instance_size
  storage_details                   = var.storage_details
  vm_image                          = var.vm_image
  vm_image_id                       = var.vm_image_id
  vm_user                           = var.vm_user
  security_groups_config            = local.security_groups_config
  security_group_ids                = var.security_group_ids
  attach_persistent_public_ip       = var.attach_persistent_public_ip
  use_public_ip                     = var.use_public_ip
  additional_install_parameters     = var.additional_install_parameters
  password                          = var.password
  generate_access_tokens            = var.generate_access_tokens
  ssh_key_path                      = var.ssh_key.ssh_private_key_file_path
  binaries_location                 = var.binaries_location
  tarball_url                       = var.tarball_url
  hadr_dr_node                      = var.hadr_dr_node
  main_node_sonarw_public_key       = var.main_node_sonarw_public_key
  main_node_sonarw_private_key      = var.main_node_sonarw_private_key
  proxy_info                        = var.ingress_communication_via_proxy
  skip_instance_health_verification = var.skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_private_key_secret_name
  sonarw_public_key_content         = var.sonarw_public_key_content
  base_directory                    = var.base_directory
  tags                              = var.tags
  cloud_init_timeout                = var.cloud_init_timeout
  send_usage_statistics             = var.send_usage_statistics
}