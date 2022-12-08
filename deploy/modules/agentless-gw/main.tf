
resource "random_string" "gw_id" {
  length  = 8
  special = false
}

module "gw_instance" {
  source                        = "../../modules/sonar-base-instance"
  resource_type                 = "gw"
  name                          = var.name
  subnet_id                     = var.subnet_id
  key_pair                      = var.key_pair
  ec2_instance_type             = var.instance_type
  ebs_details                   = var.ebs_details
  ami_name_tag                  = var.ami_name_tag
  sg_ingress_cidr               = var.sg_ingress_cidr
  public_ip                     = var.public_ip
  iam_instance_profile_id       = aws_iam_instance_profile.dsf_gw_instance_iam_profile.name
  additional_install_parameters = var.additional_install_parameters
  admin_password                = var.admin_password
  ssh_key_path                  = var.ssh_key_path
  installation_location         = var.installation_location
  sonarw_public_key             = var.sonarw_public_key
  proxy_address                 = var.proxy_address
  proxy_private_key             = var.proxy_private_key
}
