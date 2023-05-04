provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.4.2" # latest release tag
}

locals {
  deployment_name_salted                = join("-", [var.deployment_name, module.globals.salt])
  workstation_cidr_24                   = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
  workstation_cidr                      = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  admin_analytics_registration_password = var.admin_analytics_registration_password != null ? var.admin_analytics_registration_password : module.globals.random_password
  archiver_password                     = local.admin_analytics_registration_password
  archiver_user                         = var.archiver_user != null ? var.archiver_user : join("-", [var.deployment_name, module.globals.salt, "archiver-user"])
  tags                                  = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  admin_subnet                          = var.subnet_ids != null ? var.subnet_ids.admin_subnet_id : module.vpc[0].public_subnets[0]
  analytics_subnet                      = var.subnet_ids != null ? var.subnet_ids.analytics_subnet_id : module.vpc[0].private_subnets[0]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  count = var.subnet_ids == null ? 1 : 0

  name = join("-", [local.deployment_name_salted, module.globals.current_user_name])
  cidr = var.vpc_ip_range

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(module.globals.availability_zones, 0, 2)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  map_public_ip_on_launch = true
}

module "key_pair" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.2" # latest release tag
  key_name_prefix          = "imperva-dsf-dra-"
  private_key_pem_filename = "ssh_keys/dsf_dra_ssh_key-${terraform.workspace}"
}

module "dra_admin" {
  source                                = "../../../modules/aws/dra/dra-admin"
  friendly_name                         = join("-", [local.deployment_name_salted, "admin"])
  subnet_id                             = local.admin_subnet
  admin_ami_id                          = var.admin_ami_id
  admin_analytics_registration_password = local.admin_analytics_registration_password
  instance_type                         = var.admin_instance_type
  # vpc_security_group_ids = ["${aws_security_group.admin-instance.id}"]
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  # ebs = var.admin_ebs_details
  depends_on = [
    module.vpc
  ]
}

module "analytics_server_group" {
  count                                     = var.analytics_server_count
  source                                    = "../../../modules/aws/dra/dra-analytics"
  friendly_name                           = join("-", [local.deployment_name_salted, "analytics-server", count.index])
  subnet_id                                 = local.analytics_subnet
  analytics_ami_id                          = var.analytics_ami_id
  admin_analytics_registration_password_arn = module.dra_admin.admin_analytics_registration_password_secret_arn
  instance_type                             = var.analytics_instance_type
  # vpc_security_group_ids = ["${aws_security_group.admin-instance.id}"]
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  archiver_user                             = local.archiver_user
  archiver_password                         = local.archiver_password
  admin_server_private_ip                   = module.dra_admin.private_ip
  admin_server_public_ip                    = module.dra_admin.public_ip
  # ebs = var.analitycs_group_ebs_details
  depends_on = [
    module.vpc
  ]
}




# resource "aws_instance" "jump_server" {
#   ami           = data.aws_ssm_parameter.centOS.value
#   instance_type = var.instance_type
#   subnet_id = aws_subnet.public-1.id
#   vpc_security_group_ids = ["${aws_security_group.jump_server.id}"]
#   user_data = file ("./bootstrap_jumpserver.sh")
#   key_name = var.key

#   tags = {
#     Name = "Jump-Server-on-centos"
#     stage = "Test"
#   }
# }
# # ----------- Output the public ID of the Web Server ----------------

# output "web" {
#   value = [aws_instance.web.private_ip]
# }


