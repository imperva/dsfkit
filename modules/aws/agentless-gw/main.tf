
resource "random_string" "gw_id" {
  length  = 8
  special = false
}

module "gw_instance" {
  source                        = "../../../modules/aws/sonar-base-instance"
  resource_type                 = "gw"
  name                          = var.friendly_name
  subnet_id                     = var.subnet_id
  security_group_id             = var.security_group_id
  key_pair                      = var.ssh_key_pair.ssh_public_key_name
  ec2_instance_type             = var.instance_type
  ebs_details                   = var.ebs
  ami                           = var.ami
  sg_ingress_cidr               = var.ingress_communication.full_access_cidr_list
  role_arn                      = var.role_arn
  attach_public_ip              = var.attach_public_ip
  use_public_ip                 = var.use_public_ip
  additional_install_parameters = var.additional_install_parameters
  web_console_admin_password    = var.web_console_admin_password
  web_console_admin_password_secret_name = var.web_console_admin_password_secret_name
  ssh_key_path                  = var.ssh_key_pair.ssh_private_key_file_path
  binaries_location             = var.binaries_location
  hub_sonarw_public_key         = var.hub_sonarw_public_key
  hadr_secondary_node           = var.hadr_secondary_node
  sonarw_public_key             = var.sonarw_public_key
  sonarw_private_key            = var.sonarw_private_key
  proxy_info = {
    proxy_address      = var.ingress_communication_via_proxy.proxy_address
    proxy_ssh_key_path = var.ingress_communication_via_proxy.proxy_private_ssh_key_path
    proxy_ssh_user     = var.ingress_communication_via_proxy.proxy_ssh_user
  }
  skip_instance_health_verification = var.skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  internal_hub_private_key_secret_name = var.internal_hub_private_key_secret_name
  internal_hub_public_key = var.internal_hub_public_key
  internal_gw_private_key_secret_name = var.internal_gw_private_key_secret_name
  internal_gw_public_key = var.internal_gw_public_key
}
