########################################################
###############  SonarG Instance Configs ###############
########################################################

resource "random_uuid" "uuid" {}

data "template_file" "gw_cloudinit" {
  template = file("${path.module}/gw_cloudinit.tpl")
  vars = {
    name                                = var.name
    admin_password                      = var.admin_password
    secadmin_password                   = var.secadmin_password
    sonarg_pasword                      = var.sonarg_pasword
    sonargd_pasword                     = var.sonargd_pasword
    dsf_gateway_public_key_name         = var.dsf_gateway_public_key_name
    dsf_gateway_private_key_name        = var.dsf_gateway_private_key_name
    dsf_hub_public_authorized_key       = var.dsf_hub_public_authorized_key
    s3_bucket                           = var.s3_bucket
    dsf_version                         = var.dsf_version
    dsf_install_tarball_path            = var.dsf_install_tarball_path
    additional_parameters               = var.additional_parameters
    hub_ip                              = var.hub_ip
    uuid                                = random_uuid.uuid.result
  }
}

module "gw_instance" {
  source                       = "../../modules/dsf_base_instance"
  name                         = var.name
  subnet_id                    = var.subnet_id
  ec2_user_data                = data.template_file.gw_cloudinit.rendered
  key_pair                     = var.key_pair
  key_pair_pem_local_path      = var.key_pair_pem_local_path
  ec2_instance_type            = var.ec2_instance_type
  aws_ami_name                 = var.aws_ami_name
  ebs_disk_size                = var.ebs_disk_size
  security_group_ingress_cidrs = var.security_group_ingress_cidrs
  dsf_iam_profile_name         = var.dsf_iam_profile_name
}
