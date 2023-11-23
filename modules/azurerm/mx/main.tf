locals {
  dam_model          = "AVM150"
  resource_type      = "mx"
  mx_address_for_api = module.mx.public_ip != null ? module.mx.public_ip : module.mx.private_ip
  security_groups_config = [
    {
      name            = ["web", "console", "and", "api"]
      internet_access = false
      udp             = []
      tcp             = [8083]
      cidrs           = concat(var.allowed_web_console_and_api_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["other"]
      internet_access = true
      udp             = []
      tcp             = [22]
      cidrs           = concat(var.allowed_ssh_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["agent", "gateway"]
      internet_access = false
      udp             = []
      tcp             = [8083, 8085]
      cidrs           = concat(var.allowed_agent_gw_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["hub"]
      internet_access = false
      udp             = []
      tcp             = [8083]
      cidrs           = concat(var.allowed_hub_cidrs, var.allowed_all_cidrs)
    },
    # {
    #   name = ["som"]
    #   udp = []
    #   tcp = [8083, 8084, 8085]
    #   cidrs = []
    # },
    # {
    #   name = ["syslog"]
    #   udp = [514]
    #   tcp = []
    #   cidrs = []
    # },
    # {
    #   name = ["service", "monitor"]
    #   udp = []
    #   tcp = [2812]
    #   cidrs = []
    # },
  ]
}
#
locals {
#  large_scale_arg = var.large_scale_mode == true ? "--large_scale" : ""
#  user_data_commands = [
#    "/opt/SecureSphere/etc/ec2/ec2_auto_ftl --init_mode --user=${var.vm_user} --serverPassword=%mxPassword% --secure_password=%securePassword% --system_password=%securePassword% --timezone=${var.timezone} --time_servers=default --dns_servers=default --dns_domain=default --management_interface=eth0 --check_server_status --initiate_services ${local.license_params} ${local.large_scale_arg}"
#  ]
#
#  https_auth_header = base64encode("admin:${var.mx_password}")
#  timeout           = 60 * 40
#
#  readiness_commands = templatefile("${path.module}/readiness.tftpl", {
#    mx_address        = local.mx_address_for_api
#    https_auth_header = local.https_auth_header
#  })
}

module "mx" {
  source                      = "../../../modules/azurerm/dam-base-instance"
  resource_group              = var.resource_group
  name                        = var.friendly_name
  dam_version                 = var.dam_version
  dam_model                   = local.dam_model
  vm_user                     = var.vm_user
  vm_image                    = var.vm_image
  resource_type               = local.resource_type
#  mx_password                 = var.mx_password
#  secure_password             = var.secure_password
  security_groups_config      = local.security_groups_config
  security_group_ids          = var.security_group_ids
  subnet_id                   = var.subnet_id
#  user_data_commands          = local.user_data_commands
  public_ssh_key               = var.ssh_key.ssh_public_key
  attach_persistent_public_ip = var.attach_persistent_public_ip
#  instance_readiness_params = {
#    commands = local.readiness_commands
#    enable   = true
#    timeout  = local.timeout
#  }
  tags                  = var.tags
  send_usage_statistics = var.send_usage_statistics
}
