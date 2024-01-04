locals {
  gateway_group_name = var.gateway_group_name == null ? random_uuid.gateway_group_name.result : var.gateway_group_name
  dam_model          = var.gw_model
  resource_type      = "agent-gw"

  security_groups_config = [ #  https://docs.imperva.com/bundle/v14.14-dam-on-microsoft-azure-installation-guide/page/83147.htm
    {
      name            = ["agent"]
      internet_access = false
      udp             = []
      tcp             = [443, var.agent_listener_port]
      cidrs           = concat(var.allowed_agent_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["mx"]
      internet_access = false
      udp             = []
      tcp             = [443]
      cidrs           = concat(var.allowed_mx_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["other"]
      internet_access = true
      udp             = []
      tcp             = [22]
      cidrs           = concat(var.allowed_ssh_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["agent", "gateway", "clusters"]
      internet_access = false
      udp             = [3792]
      tcp             = [3792, 7700]
      cidrs           = concat(var.allowed_gw_clusters_cidrs, var.allowed_all_cidrs)
    }
  ]

  management_server_host_for_api_access = var.management_server_host_for_api_access != null ? var.management_server_host_for_api_access : var.management_server_host_for_registration
}

resource "random_uuid" "gateway_group_name" {}

locals {
  ftl_script     = "/opt/SecureSphere/azure/bin/azure_arm --component='Gateway' --product='DAM' --timezone='${var.timezone}' --password='${var.mx_password}' --gateway_group='${local.gateway_group_name}' --management_ip='${var.management_server_host_for_registration}' --model_type='${var.gw_model}' --gateway_mode='sniffing' --agent_listener_port=${var.agent_listener_port} --agent_listener_ssl=${var.agent_listener_ssl} --sonar_only_mode='${var.large_scale_mode}' --scaling=false"
  cluster_commands = [
    "source /etc/profile.d/imperva.sh",
    "/opt/SecureSphere/etc/impctl/bin/impctl service stop --teardown --transient gateway",
    "/opt/SecureSphere/etc/impctl/bin/impctl gateway cluster config --cluster-port=3792 --cluster-interface=eth0",
    "/opt/SecureSphere/etc/impctl/bin/impctl gateway register",
    "/opt/SecureSphere/etc/impctl/bin/impctl service start --prepare --transient gateway",
  ]
  custom_scripts = {
    "ftl" = join(" && ", concat([local.ftl_script], local.cluster_commands))
  }
  https_auth_header = base64encode("admin:${var.mx_password}")
  timeout           = 60 * 25

  readiness_commands = templatefile("${path.module}/readiness.tftpl", {
    mx_address         = var.management_server_host_for_api_access
    gateway_group_name = local.gateway_group_name
    https_auth_header  = local.https_auth_header
    gateway_id         = module.agent_gw.display_name
  })
}

module "agent_gw" {
  source                 = "../../../modules/azurerm/dam-base-instance"
  resource_group         = var.resource_group
  name                   = var.friendly_name
  dam_version            = var.dam_version
  vm_user                = var.vm_user
  vm_image               = var.vm_image
  resource_type          = local.resource_type
  dam_model              = local.dam_model
  storage_details        = var.storage_details
  security_groups_config = local.security_groups_config
  security_group_ids     = var.security_group_ids
  subnet_id              = var.subnet_id
  custom_scripts         = local.custom_scripts
  public_ssh_key         = var.ssh_key.ssh_public_key
  instance_readiness_params = {
    commands = local.readiness_commands
    enable   = true
    timeout  = local.timeout
  }
  attach_persistent_public_ip = false
  tags                        = var.tags
  send_usage_statistics       = var.send_usage_statistics
}
