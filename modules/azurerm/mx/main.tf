locals {
  dam_model          = "MVM150"
  resource_type      = "mx"
  mx_address_for_api = module.mx.public_ip != null ? module.mx.public_ip : module.mx.private_ip
  security_groups_config = [ # https://docs.imperva.com/bundle/v14.14-dam-on-microsoft-azure-installation-guide/page/83147.htm
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

locals {
  gateway_group = var.friendly_name
  ftl_script    = "/opt/SecureSphere/azure/bin/azure_arm --component='Management' --sonar_only_mode='false' --timezone='${var.timezone}' --password='${var.mx_password}' --gateway_group='${local.gateway_group}' --enc_lic='${local.encrypted_license}' --pass_phrase='${local.license_passphrase}' --large_scale='${var.large_scale_mode}'"
  custom_scripts = {
    "ftl" = local.ftl_script
  }

  https_auth_header = base64encode("admin:${var.mx_password}")
  timeout           = 60 * 40

  readiness_commands = templatefile("${path.module}/readiness.tftpl", {
    mx_address        = local.mx_address_for_api
    https_auth_header = local.https_auth_header
  })
}

module "mx" {
  source                      = "../../../modules/azurerm/dam-base-instance"
  resource_group              = var.resource_group
  name                        = var.friendly_name
  dam_version                 = var.dam_version
  vm_user                     = var.vm_user
  vm_image                    = var.vm_image
  resource_type               = local.resource_type
  dam_model                   = local.dam_model
  storage_details             = var.storage_details
  security_groups_config      = local.security_groups_config
  security_group_ids          = var.security_group_ids
  subnet_id                   = var.subnet_id
  custom_scripts              = local.custom_scripts
  public_ssh_key              = var.ssh_key.ssh_public_key
  attach_persistent_public_ip = var.attach_persistent_public_ip
  instance_readiness_params = {
    commands = local.readiness_commands
    enable   = true
    timeout  = local.timeout
  }
  tags                  = var.tags
  send_usage_statistics = var.send_usage_statistics
}
