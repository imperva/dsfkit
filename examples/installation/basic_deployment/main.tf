provider "aws" {
  default_tags {
    tags = local.tags
  }
  profile = var.aws_profile
  region  = var.aws_region
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.3.6" # latest release tag
  sonar_version = var.sonar_version
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  workstation_cidr_24 = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tarball_location           = module.globals.tarball_location
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}

##############################
# Generating ssh keys
##############################
module "key_pair_hub" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.6" # latest release tag
  key_name_prefix          = "imperva-dsf-hub"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-hub-${terraform.workspace}"
}

module "key_pair_gw" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.6" # latest release tag
  key_name_prefix          = "imperva-dsf-gw"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw-${terraform.workspace}"
}

##############################
# Generating deployment
##############################
module "hub" {
  source                              = "imperva/dsf-hub/aws"
  version                             = "1.3.6" # latest release tag
  friendly_name                       = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                           = var.subnet_hub
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  ebs                                 = var.hub_ebs_details
  create_and_attach_public_elastic_ip = false
  ami_name_tag                        = var.hub_ami_name
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_hub.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair_hub.key_pair.key_pair_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = concat(local.workstation_cidr, ["${module.hub_secondary.private_ip}/32"])
    use_public_ip                           = false
  }
  skip_instance_health_verification = var.hub_skip_instance_health_verification
}

module "hub_secondary" {
  source                              = "imperva/dsf-hub/aws"
  version                             = "1.3.6" # latest release tag
  friendly_name                        = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                            = var.subnet_hub_secondary
  binaries_location                    = local.tarball_location
  web_console_admin_password           = local.web_console_admin_password
  ebs                                  = var.hub_ebs_details
  create_and_attach_public_elastic_ip  = false
  ami_name_tag                         = var.hub_ami_name
  hadr_secondary_node                  = true
  sonarw_public_key                    = module.hub.sonarw_public_key
  sonarw_private_key                   = module.hub.sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_hub.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair_hub.key_pair.key_pair_name
  }
  ingress_communication = {
    additional_web_console_access_cidr_list = var.web_console_cidr
    full_access_cidr_list                   = concat(local.workstation_cidr, ["${module.hub.private_ip}/32"])
    use_public_ip                           = false
  }
  skip_instance_health_verification = var.hub_skip_instance_health_verification
}

module "agentless_gw_group_primary" {
  count                               = var.gw_count
  source                              = "imperva/dsf-agentless-gw/aws"
  version                             = "1.3.6" # latest release tag
  friendly_name                       = join("-", [local.deployment_name_salted, "gw", count.index, "primary"])
  subnet_id                           = var.subnet_gw
  ebs                                 = var.gw_group_ebs_details
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  hub_sonarw_public_key               = module.hub.sonarw_public_key
  create_and_attach_public_elastic_ip = false
  ami_name_tag                        = var.gw_ami_name
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_gw.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair_gw.key_pair.key_pair_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub.private_ip}/32", "${module.hub_secondary.private_ip}/32"])
    use_public_ip         = false
  }
  ingress_communication_via_proxy = {
    proxy_address              = module.hub.private_ip
    proxy_private_ssh_key_path = module.key_pair_hub.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  skip_instance_health_verification = var.gw_skip_instance_health_verification
}

module "agentless_gw_group_secondary" {
  count                               = var.gw_count
  source                              = "imperva/dsf-agentless-gw/aws"
  version                             = "1.3.6" # latest release tag
  friendly_name                       = join("-", [local.deployment_name_salted, "gw", count.index, "secondary"])
  subnet_id                           = var.subnet_gw_secondary
  ebs                                 = var.gw_group_ebs_details
  binaries_location                   = local.tarball_location
  web_console_admin_password          = local.web_console_admin_password
  hub_sonarw_public_key               = module.hub.sonarw_public_key
  hadr_secondary_node                 = true
  sonarw_public_key                   = module.agentless_gw_group_primary[count.index].sonarw_public_key
  sonarw_private_key                  = module.agentless_gw_group_primary[count.index].sonarw_private_key
  create_and_attach_public_elastic_ip = false
  ami_name_tag                        = var.gw_ami_name
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair_gw.key_pair_private_pem.filename
    ssh_public_key_name       = module.key_pair_gw.key_pair.key_pair_name
  }
  ingress_communication = {
    full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub.private_ip}/32", "${module.hub_secondary.private_ip}/32", "${module.agentless_gw_group_primary[count.index].private_ip}/32"])
    use_public_ip         = false
  }
  ingress_communication_via_proxy = {
    proxy_address              = module.hub.private_ip
    proxy_private_ssh_key_path = module.key_pair_hub.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
}

# assumes that ingress_ports output of all gateways is the same
locals {
  primary_gw_sg_and_secondary_gw_ip_combinations = setproduct(
    [for idx, gw in module.agentless_gw_group_primary: gw.sg_id],
    [for idx, gw in module.agentless_gw_group_secondary: gw.private_ip],
    [for idx, ingress_port in module.agentless_gw_group_secondary[0].ingress_ports : ingress_port]
  )
}

# adds secondary gw cidr to ingress cidrs of the primary gw's sg
resource aws_security_group_rule "primary_gw_sg_secondary_cidr_ingress" {
  count             = length(local.primary_gw_sg_and_secondary_gw_ip_combinations)
  type              = "ingress"
  from_port         = local.primary_gw_sg_and_secondary_gw_ip_combinations[count.index][2]
  to_port           = local.primary_gw_sg_and_secondary_gw_ip_combinations[count.index][2]
  protocol          = "tcp"
  cidr_blocks       = ["${local.primary_gw_sg_and_secondary_gw_ip_combinations[count.index][1]}/32"]
  security_group_id = local.primary_gw_sg_and_secondary_gw_ip_combinations[count.index][0]
}

locals {
  hub_gw_combinations = setproduct(
    [module.hub, module.hub_secondary],
    concat(
      [for idx, val in module.agentless_gw_group_primary : val],
      [for idx, val in module.agentless_gw_group_secondary : val]
    )
  )
}

module "federation" {
  count   = length(local.hub_gw_combinations)
  source                    = "imperva/dsf-federation/null"
  version                   = "1.3.6" # latest release tag
  gw_info = {
    gw_ip_address           = local.hub_gw_combinations[count.index][1].private_ip
    gw_private_ssh_key_path = module.key_pair_gw.key_pair_private_pem.filename
    gw_ssh_user             = local.hub_gw_combinations[count.index][1].ssh_user
  }
  hub_info = {
    hub_ip_address           = local.hub_gw_combinations[count.index][0].private_ip
    hub_private_ssh_key_path = module.key_pair_hub.key_pair_private_pem.filename
    hub_ssh_user             = local.hub_gw_combinations[count.index][0].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub.private_ip
    proxy_private_ssh_key_path = module.key_pair_hub.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.hub,
    module.hub_secondary,
    module.agentless_gw_group_primary,
    module.agentless_gw_group_secondary
  ]
}

module "hub_hadr" {
  source                   = "imperva/dsf-hadr/null"
  version                  = "1.3.6" # latest release tag
  dsf_primary_ip           = module.hub.private_ip
  dsf_primary_private_ip   = module.hub.private_ip
  dsf_secondary_ip         = module.hub_secondary.private_ip
  dsf_secondary_private_ip = module.hub_secondary.private_ip
  ssh_key_path             = module.key_pair_hub.key_pair_private_pem.filename
  ssh_user                 = module.hub.ssh_user
  depends_on = [
    module.federation,
    module.hub,
    module.hub_secondary
  ]
}

module "agentless_gw_group_hadr" {
  count                        = var.gw_count
  source                       = "imperva/dsf-hadr/null"
  version                      = "1.3.6" # latest release tag
  dsf_primary_ip               = module.agentless_gw_group_primary[count.index].private_ip
  dsf_primary_private_ip       = module.agentless_gw_group_primary[count.index].private_ip
  dsf_secondary_ip             = module.agentless_gw_group_secondary[count.index].private_ip
  dsf_secondary_private_ip     = module.agentless_gw_group_secondary[count.index].private_ip
  ssh_key_path                 = module.key_pair_gw.key_pair_private_pem.filename
  ssh_user                     = module.agentless_gw_group_primary[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub.private_ip
    proxy_private_ssh_key_path = module.key_pair_hub.key_pair_private_pem.filename
    proxy_ssh_user             = module.hub.ssh_user
  }
  depends_on = [
    module.federation,
    module.agentless_gw_group_primary,
    module.agentless_gw_group_secondary
  ]
}

module "statistics" {
  source  = "../../../modules/aws/statistics"
}
