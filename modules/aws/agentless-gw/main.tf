locals {
  security_groups_config = [ # https://docs.imperva.com/bundle/v4.11-sonar-installation-and-setup-guide/page/78702.htm
    {
      name            = ["other"]
      internet_access = true
      udp             = []
      tcp             = [22]
      cidrs           = concat(var.allowed_ssh_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["hub"]
      internet_access = false
      udp             = []
      tcp             = [22, 8443]
      cidrs           = concat(var.allowed_hub_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["agentless", "gw", "replica", "set"]
      internet_access = false
      udp             = []
      tcp             = [3030, 27117, 22]
      cidrs           = concat(var.allowed_agentless_gw_cidrs, var.allowed_all_cidrs)
    }
  ]
}

resource "random_string" "gw_id" {
  length  = 8
  special = false
}

module "gw_instance" {
  source                            = "../../../modules/aws/sonar-base-instance"
  resource_type                     = "agentless-gw"
  name                              = var.friendly_name
  subnet_id                         = var.subnet_id
  security_groups_config            = local.security_groups_config
  security_group_ids                = var.security_group_ids
  key_pair                          = var.ssh_key_pair.ssh_public_key_name
  ec2_instance_type                 = var.instance_type
  ebs_details                       = var.ebs
  ami                               = var.ami
  instance_profile_name             = var.instance_profile_name
  additional_install_parameters     = var.additional_install_parameters
  admin_password                    = var.admin_password
  secadmin_password                 = var.secadmin_password
  sonarg_password                   = var.sonarg_password
  sonargd_password                  = var.sonargd_password
  admin_password_secret_name        = var.admin_password_secret_name
  secadmin_password_secret_name     = var.secadmin_password_secret_name
  sonarg_password_secret_name       = var.sonarg_password_secret_name
  sonargd_password_secret_name      = var.sonargd_password_secret_name
  ssh_key_path                      = var.ssh_key_pair.ssh_private_key_file_path
  binaries_location                 = var.binaries_location
  hub_sonarw_public_key             = var.hub_sonarw_public_key
  hadr_secondary_node               = var.hadr_secondary_node
  primary_node_sonarw_public_key    = var.primary_node_sonarw_public_key
  primary_node_sonarw_private_key   = var.primary_node_sonarw_private_key
  proxy_info                        = var.gw_proxy_info
  skip_instance_health_verification = var.skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  use_public_ip                     = false
  attach_persistent_public_ip       = false
  sonarw_private_key_secret_name    = var.sonarw_private_key_secret_name
  sonarw_public_key_content         = var.sonarw_public_key_content
  volume_attachment_device_name     = var.volume_attachment_device_name
  tags                              = var.tags
}

#################################
# Federation script
#################################

locals {
  lock_shell_cmds = file("${path.module}/grab_lock.sh")
  federate_hub_cmds = templatefile("${path.module}/federate_hub.tftpl", {
    ssh_key_path                   = var.ssh_key_pair.ssh_private_key_file_path
    dsf_gw_ip                      = module.gw_instance.private_ip
    dsf_hub_ssh_ip                 = var.hub_info.ssh_ip_address
    dsf_hub_federation_ip          = var.hub_info.federation_ip_address
    hub_ssh_user                   = var.hub_info.ssh_user
    hub_proxy_address              = var.hub_info.proxy_ip_address != null ? var.hub_info.proxy_ip_address : ""
    hub_proxy_private_ssh_key_path = var.hub_info.proxy_private_ssh_key_path != null ? var.hub_info.proxy_private_ssh_key_path : ""
    hub_proxy_ssh_user             = var.hub_info.proxy_ssh_user != null ? var.hub_info.proxy_ssh_user : ""
  })
  federate_gw_cmds = templatefile("${path.module}/federate_gw.tftpl", {
    ssh_key_path                  = var.ssh_key_pair.ssh_private_key_file_path
    dsf_gw_ip                     = module.gw_instance.private_ip
    gw_ssh_user                   = module.gw_instance.ssh_user
    gw_proxy_address              = var.gw_proxy_info.ip_address
    gw_proxy_private_ssh_key_path = var.gw_proxy_info.private_ssh_key_path != null ? var.gw_proxy_info.private_ssh_key_path : ""
    gw_proxy_ssh_user             = var.gw_proxy_info.ssh_user
  })
  sleep_value = "40s"
}

resource "time_sleep" "sleep" {
  create_duration = local.sleep_value
  depends_on = [
    module.gw_instance
  ]
}

resource "null_resource" "federate_cmds" {
  provisioner "local-exec" {
    command     = "${local.lock_shell_cmds} ${local.federate_hub_cmds} ${local.federate_gw_cmds}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [
    time_sleep.sleep,
  ]
  # triggers = {
  #   binaries_location = "${var.binaries_location.s3_bucket}/${var.binaries_location.s3_key}",
  # }
}
