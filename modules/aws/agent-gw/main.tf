locals {
  volume_size         = "500"
  gateway_group_id           = var.gateway_group_id == null ? random_uuid.gateway_group_id.result : var.gateway_group_id
  required_tcp_ports = [22, 443, 80, 3792, 7700]
  required_udp_ports = [3792]
  dam_model          = var.gw_model
  resource_type      = "agent-gw"
}

resource "random_uuid" "gateway_group_id" {}

locals {
  user_data_commands = [
    "/opt/SecureSphere/etc/ec2/create_audit_volume --volumesize=${local.volume_size}",
    "/opt/SecureSphere/etc/ec2/ec2_auto_ftl --init_mode  --user=${var.ssh_user} --gateway_group=${local.gateway_group_id} --secure_password=%securePassword% --imperva_password=%securePassword% --timezone=${var.timezone} --time_servers=default --dns_servers=default --dns_domain=default --management_server_ip=${var.management_server_host} --management_interface=eth0 --internal_data_interface=eth0 --external_data_interface=eth0 --check_server_status --check_gateway_received_configuration --register --initiate_services --set_sniffing --listener_port=${var.agent_listener_port} --agent_listener_ssl=${var.agent_listener_ssl} --cluster-enabled --cluster-port=3792 --product=DAM --waitForServer"
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
  timeout          = 60 * 25

  readiness_commands = templatefile("${path.module}/readiness.sh", {
    mx_address = "unkown"
    gateway_group_id = local.gateway_group_id
    https_auth_header = local.https_auth_header
    gateway_id = module.agent_gw.instance_id
  })
}

module "agent_gw" {
  source          = "../../../modules/aws/dam-base-instance"
  name            = join("-", [var.friendly_name, local.resource_type])
  dam_version     = var.dam_version
  resource_type   = local.resource_type
  dam_model       = local.dam_model
  mx_password     = var.mx_password
  secure_password = var.secure_password
  internal_ports = {
    tcp = local.required_tcp_ports
    udp = local.required_udp_ports
  }
  subnet_id          = var.subnet_id
  user_data_commands = local.user_data_commands
  sg_ingress_cidr    = var.sg_ingress_cidr
  sg_ssh_cidr        = var.sg_ssh_cidr
  security_group_ids = concat(var.security_group_ids, [aws_security_group.dsf_agent_sg.id])
  iam_actions        = local.iam_actions
  key_pair           = var.key_pair
  attach_public_ip   = false
  instance_readiness_params = {
    commands = local.readiness_commands
    enable   = false
    timeout  = local.timeout
  }
}
