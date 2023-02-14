#################################
# Actual Hub instance
#################################

module "hub_instance" {
  source          = "../../../modules/azurerm/sonar-base-instance"
  resource_type   = "hub"
  resource_group  = var.resource_group
  name            = var.friendly_name
  subnet_id       = var.subnet_id
#  security_group_id                   = var.security_group_id
  public_ssh_key  = var.ssh_key.ssh_public_key
  instance_type   = var.instance_type
  storage_details = var.storage_details
  vm_image        = var.vm_image
  vm_user         = var.vm_user
  # web_console_cidr                    = var.ingress_communication.additional_web_console_access_cidr_list
  sg_ingress_cidr                     = var.ingress_communication.full_access_cidr_list
#  role_arn                            = var.role_arn
  create_and_attach_public_elastic_ip = var.create_and_attach_public_elastic_ip
  use_public_ip                       = var.ingress_communication.use_public_ip
  additional_install_parameters = var.additional_install_parameters
  web_console_admin_password    = var.web_console_admin_password
  ssh_key_path    = var.ssh_key.ssh_private_key_file_path
  binaries_location             = var.binaries_location
  hadr_secondary_node           = var.hadr_secondary_node
  sonarw_public_key             = var.sonarw_public_key
  sonarw_private_key            = var.sonarw_private_key
  proxy_info = {
    proxy_address      = var.ingress_communication_via_proxy.proxy_address
    proxy_ssh_key_path = var.ingress_communication_via_proxy.proxy_private_ssh_key_path
    proxy_ssh_user     = var.ingress_communication_via_proxy.proxy_ssh_user
  }
  skip_instance_health_verification = var.skip_instance_health_verification
}