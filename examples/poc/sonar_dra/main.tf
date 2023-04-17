provider "aws" {
  region = var.region
}

locals {
  networks = [for index in range (6):cidrsubnet(var.vpc_cidr,8,index)]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  map_public_ip_on_launch = true
  name = "DSF_DRA_VPC"
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



module "dra_admin" {
  source = "../../../modules/aws/dra-admin"
  registration_password = var.registration_password
  admin_ami_id           = var.admin_ami_id
  instance_type = var.instance_type
  subnet_id = module.vpc.public_subnets[0]
  # vpc_security_group_ids = ["${aws_security_group.admin-server-demo.id}"]
  key = var.key
  region = var.region
  vpc_id = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
}


module "analitycs_server" {
  source = "../../../modules/aws/dra-analitycs"
  registration_password = var.registration_password
  analytics_ami_id           = var.analytics_ami_id
  instance_type = var.instance_type
  subnet_id = module.vpc.private_subnets[0]
  # vpc_security_group_ids = ["${aws_security_group.admin-server-demo.id}"]
  key = var.key
  region = var.region
  analytics_user = var.analytics_user
  analytics_password = var.analytics_password
  admin_server_ip = module.dra_admin.private_ip
  vpc_id = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
}

# data "template_file" "analytics_bootstrap" {
#   template = file("${path.module}/analytics_bootstrap.tpl")
#   vars = {
#     registration_password = var.registration_password
#     analytics_user = var.analytics_user
#     analytics_password = var.analytics_password
#     admin_server_ip = module.dra_admin.private_ip
#   }
# }
# resource "aws_instance" "dra_analytics" {
#   ami           = var.analytics_ami_id
#   instance_type = var.instance_type
#   subnet_id = module.vpc.private_subnets[0]
#   vpc_security_group_ids = ["${aws_security_group.analytics-server-demo.id}"]
#   key_name = var.key
#   user_data = data.template_file.analytics_bootstrap.rendered
#   tags = {
#     Name = "DRA-Analytics-server"
#     stage = "Test"
#   }
# }




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


