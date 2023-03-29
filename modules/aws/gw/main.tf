locals {
  ami_username = "ec2-user"

  timezone = "UTC"

  VolumeSize = "500"
}

resource "random_uuid" "gw_group" {}

data "aws_region" "current" {}

locals {
  large_scale_mode = false
  user_data_commands = [
    "/opt/SecureSphere/etc/ec2/create_audit_volume --volumesize=${local.VolumeSize}",
    "/opt/SecureSphere/etc/ec2/ec2_auto_ftl --init_mode  --user=${local.ami_username} --gateway_group=${random_uuid.gw_group.result} --secure_password=%securePassword% --imperva_password=%securePassword% --timezone=${local.timezone} --time_servers=default --dns_servers=default --dns_domain=default --management_server_ip=${var.management_server_host} --management_interface=eth0 --internal_data_interface=eth0 --external_data_interface=eth0 --check_server_status --check_gateway_received_configuration --register --initiate_services ${local.large_scale_mode} --set_sniffing --listener_port=${var.agent_listener_port} --agent_listener_ssl=${var.agent_listener_ssl} --cluster-enabled --cluster-port=3792 --product=DAM --waitForServer"
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
}

module "gw" {
  source           = "../../../modules/aws/dam-base-instance"
  name             = join("-", [var.friendly_name, "agent-gw"])
  resource_type    = "agent-gw"
  ses_model        = var.gw_model
  imperva_password = var.password
  secure_password  = var.password
  ports = {
    tcp = [22, 443, 80, 3792, 7700, var.agent_listener_port]
    udp = [3792]
  }
  subnet_id           = var.subnet_id
  user_data_commands  = local.user_data_commands
  sg_ingress_cidr     = var.sg_ingress_cidr
  sg_ssh_cidr         = var.sg_ssh_cidr
  iam_actions         = local.iam_actions
  key_pair            = var.key_pair
  attach_public_ip    = true
}
