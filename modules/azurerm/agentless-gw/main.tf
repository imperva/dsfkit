
resource "random_string" "gw_id" {
  length  = 8
  special = false
}

module "gw_instance" {
  source          = "../../../modules/azurerm/sonar-base-instance"
  resource_type   = "gw"
  resource_group  = var.resource_group
  name            = var.friendly_name
  subnet_id       = var.subnet_id
  public_ssh_key  = var.ssh_key.ssh_public_key
  ssh_key_path    = var.ssh_key.ssh_private_key_file_path
  instance_type   = var.instance_type
  storage_details = var.storage_details
  # ami_name_tag                        = var.ami_name_tag
  # ami_user                            = var.ami_user
  sg_ingress_cidr                     = var.ingress_communication.full_access_cidr_list
  create_and_attach_public_elastic_ip = var.create_and_attach_public_elastic_ip
  use_public_ip                       = var.ingress_communication.use_public_ip
  # iam_instance_profile_id             = aws_iam_instance_profile.dsf_gw_instance_iam_profile.name
  additional_install_parameters = var.additional_install_parameters
  web_console_admin_password    = var.web_console_admin_password
  binaries_location             = var.binaries_location
  hub_federation_public_key     = var.hub_federation_public_key
  proxy_info = {
    proxy_address      = var.ingress_communication_via_proxy.proxy_address
    proxy_ssh_key_path = var.ingress_communication_via_proxy.proxy_private_ssh_key_path
    proxy_ssh_user     = var.ingress_communication_via_proxy.proxy_ssh_user
  }
  skip_instance_health_verification = var.skip_instance_health_verification
}
