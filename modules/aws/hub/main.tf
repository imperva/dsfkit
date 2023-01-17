#################################
# Actual Hub instance
#################################

module "hub_instance" {
  source                              = "../../../modules/aws/sonar-base-instance"
  resource_type                       = "hub"
  name                                = var.friendly_name
  subnet_id                           = var.subnet_id
  key_pair                            = var.ssh_key_pair.ssh_public_key_name
  ec2_instance_type                   = var.instance_type
  ebs_details                         = var.ebs
  ami_name_tag                        = var.ami_name_tag
  ami_user                            = var.ami_user
  web_console_cidr                    = var.ingress_communication.additional_web_console_access_cidr_list
  sg_ingress_cidr                     = var.ingress_communication.full_access_cidr_list
  create_and_attach_public_elastic_ip = var.create_and_attach_public_elastic_ip
  use_public_ip                       = var.ingress_communication.use_public_ip
  iam_instance_profile_id             = aws_iam_instance_profile.dsf_hub_instance_iam_profile.id
  additional_install_parameters       = var.additional_install_parameters
  web_console_admin_password          = var.web_console_admin_password
  ssh_key_path                        = var.ssh_key_pair.ssh_private_key_file_path
  binaries_location                   = var.binaries_location
  hub_federation_public_key           = local.dsf_hub_ssh_public_federation_key
  sonarw_secret_name                  = local.secret_aws_name
  skip_instance_health_verification   = var.skip_instance_health_verification
}