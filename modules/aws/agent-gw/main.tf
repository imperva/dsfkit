locals {
  volume_size        = "500"
  gateway_group_name = var.gateway_group_name == null ? random_uuid.gateway_group_name.result : var.gateway_group_name
  dam_model          = var.gw_model
  resource_type      = "agent-gw"

  security_groups_config = [
    {
      name  = ["agent"]
      udp   = []
      tcp   = [443, var.agent_listener_port]
      cidrs = concat(var.allowed_agent_cidrs, var.allowed_all_cidrs)
    },
    {
      name  = ["mx"]
      udp   = []
      tcp   = [443]
      cidrs = concat(var.allowed_mx_cidrs, var.allowed_all_cidrs)
    },
    {
      name  = ["ssh"]
      udp   = []
      tcp   = [22]
      cidrs = concat(var.allowed_ssh_cidrs, var.allowed_all_cidrs)
    },
    {
      name  = ["agent", "gateway", "clusters"]
      udp   = [3792]
      tcp   = [3792, 7700]
      cidrs = concat(var.allowed_gw_clusters_cidrs, var.allowed_all_cidrs)
    }
  ]

  management_server_host_for_api_access = var.management_server_host_for_api_access != null ? var.management_server_host_for_api_access : var.management_server_host_for_registration
}

resource "random_uuid" "gateway_group_name" {}

locals {
  large_scale_arg = var.large_scale_mode == true ? "--sonar-only-mode" : ""
  user_data_commands = [
    "/opt/SecureSphere/etc/ec2/create_audit_volume --volumesize=${local.volume_size}",
    "/opt/SecureSphere/etc/ec2/ec2_auto_ftl --init_mode  --user=${var.ssh_user} --gateway_group=${local.gateway_group_name} --secure_password=%securePassword% --imperva_password=%securePassword% --timezone=${var.timezone} --time_servers=default --dns_servers=default --dns_domain=default --management_server_ip=${var.management_server_host_for_registration} --management_interface=eth0 --internal_data_interface=eth0 --external_data_interface=eth0 --check_server_status --check_gateway_received_configuration --register --initiate_services --set_sniffing --listener_port=${var.agent_listener_port} --agent_listener_ssl=${var.agent_listener_ssl} --cluster-enabled --cluster-port=3792 --product=DAM --waitForServer ${local.large_scale_arg}"
  ]
  iam_actions = ["ec2:DescribeSecurityGroups",
    "elasticloadbalancing:DescribeLoadBalancers",
    "ec2:DescribeInstanceAttribute",
    "ec2:ModifyInstanceAttribute",
    "rds:DescribeDBLogFiles",
    "rds:DownloadCompleteDBLogFile",
    "rds:DownloadDBLogFilePortion",
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:PutObjectTagging",
    "s3:PutObjectVersionAcl",
    "s3:PutObjectVersionTagging",
    "ec2:DescribeInstances",
  "ec2:AuthorizeSecurityGroupIngress"]
  https_auth_header = base64encode("admin:${var.mx_password}")
  timeout           = 60 * 25

  readiness_commands = templatefile("${path.module}/readiness.tftpl", {
    mx_address        = var.management_server_host_for_api_access
    gateway_group_name  = local.gateway_group_name
    https_auth_header = local.https_auth_header
    gateway_id        = module.agent_gw.instance_id
  })
}

module "agent_gw" {
  source                 = "../../../modules/aws/dam-base-instance"
  name                   = var.friendly_name
  dam_version            = var.dam_version
  resource_type          = local.resource_type
  dam_model              = local.dam_model
  mx_password            = var.mx_password
  secure_password        = var.secure_password
  security_groups_config = local.security_groups_config
  security_group_ids     = var.security_group_ids
  subnet_id              = var.subnet_id
  user_data_commands     = local.user_data_commands
  iam_actions            = local.iam_actions
  instance_profile_name  = var.instance_profile_name
  key_pair               = var.key_pair
  instance_readiness_params = {
    commands = local.readiness_commands
    enable   = true
    timeout  = local.timeout
  }
  attach_persistent_public_ip = false
  tags = var.tags
}
