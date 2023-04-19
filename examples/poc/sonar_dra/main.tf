provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.4.2" # latest release tag
}

locals {
  networks = [for index in range (6):cidrsubnet(var.vpc_cidr,8,index)]
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
  admin_analytics_registration_password = var.admin_analytics_registration_password != null ? var.admin_analytics_registration_password : module.globals.random_password
  archiver_password = local.admin_analytics_registration_password
  archiver_user = var.archiver_user != null ?  var.archiver_user : join("-", [var.deployment_name, module.globals.salt,"archiver-user"])
  tags = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  map_public_ip_on_launch = true
  name = join("-", [local.deployment_name_salted, "vpc"])
  cidr = var.vpc_cidr
  azs             = [ "${var.region}a", "${var.region}b"]
  private_subnets = [local.networks[0],local.networks[1]]
  public_subnets  = [local.networks[2], local.networks[3]]
  database_subnets = [local.networks[4],local.networks[5]]

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  tags = {
    Owner       = "terraform"
  }

  vpc_tags = {
    Name = module.vpc.name
  }
}


module "key_pair" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.2" # latest release tag
  key_name_prefix          = "imperva-dsf-dra-"
  private_key_pem_filename = "ssh_keys/dsf_dra_ssh_key-${terraform.workspace}"
}

module "dra_admin" {
  source = "../../../modules/aws/dra/dra-admin"
  admin_analytics_registration_password = local.admin_analytics_registration_password
  admin_ami_id           = var.admin_ami_id
  instance_type = var.instance_type
  subnet_id = module.vpc.public_subnets[0]
  deployment_name = local.deployment_name_salted
  # vpc_security_group_ids = ["${aws_security_group.admin-instance.id}"]
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  region = var.region
  vpc_id = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
  # ebs = var.admin_ebs_details
}


module "analitycs_server_group" {
  count = 2
  source = "../../../modules/aws/dra/dra-analitycs"
  admin_analytics_registration_password = local.admin_analytics_registration_password
  analytics_ami_id           = var.analytics_ami_id
  instance_type = var.instance_type
  subnet_id = module.vpc.public_subnets[0]
  deployment_name = local.deployment_name_salted
  # vpc_security_group_ids = ["${aws_security_group.admin-instance.id}"]
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  region = var.region
  analytics_user = local.archiver_user
  analytics_password = local.archiver_password
  admin_server_private_ip = module.dra_admin.private_ip
  admin_server_public_ip = module.dra_admin.public_ip
  vpc_id = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
  ebs = var.analitycs_group_ebs_details
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


