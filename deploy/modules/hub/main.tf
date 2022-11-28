#################################
# Actual Hub instance
#################################

module "hub_instance" {
  source                        = "../../modules/sonar-base-instance"
  resource_type                 = "hub"
  name                          = var.name
  subnet_id                     = var.subnet_id
  key_pair                      = var.key_pair
  ec2_instance_type             = var.instance_type
  ebs_details                   = var.ebs_details
  ami_name_tag                  = var.ami_name_tag
  web_console_cidr              = var.web_console_cidr
  sg_ingress_cidr               = var.sg_ingress_cidr
  public_ip                     = true
  iam_instance_profile_id       = aws_iam_instance_profile.dsf_hub_instance_iam_profile.id
  additional_install_parameters = var.additional_install_parameters
  admin_password                = var.admin_password
  ssh_key_path                  = var.ssh_key_path
  installation_location         = var.installation_location
  sonarw_public_key             = local.dsf_hub_ssh_federation_key
  sonarw_secret_name            = local.secret_aws_name
}