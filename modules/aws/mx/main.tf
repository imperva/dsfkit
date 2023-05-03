locals {
  license_passphrase = random_password.passphrase.result
  encrypted_license  = data.external.encrypted_license.result.cipher_text
  required_tcp_ports = [443, 514, 2812, 8081, 8083, 8084, 8085]
  required_udp_ports = []
  dam_model          = "AVM150"
  resource_type      = "mx"
  mx_address_for_api = module.mx.public_ip != null ? module.mx.public_ip : module.mx.private_ip
}

locals {
  large_scale_arg = var.large_scale_mode == true ? "--large_scale" : ""
  user_data_commands = [
    "/opt/SecureSphere/etc/ec2/ec2_auto_ftl --init_mode --user=${var.ssh_user} --serverPassword=%mxPassword% --secure_password=%securePassword% --system_password=%securePassword% --timezone=${var.timezone} --time_servers=default --dns_servers=default --dns_domain=default --management_interface=eth0 --check_server_status --initiate_services --encLic=${local.encrypted_license} --passPhrase=${local.license_passphrase} ${local.large_scale_arg}"
  ]
  iam_actions = [
    "ec2:DescribeInstances"
  ]

  https_auth_header = base64encode("admin:${var.mx_password}")
  timeout           = 60 * 30

  readiness_commands = templatefile("${path.module}/readiness.tftpl", {
    mx_address        = local.mx_address_for_api
    https_auth_header = local.https_auth_header
  })
}

module "mx" {
  source          = "../../../modules/aws/dam-base-instance"
  name            = var.friendly_name
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
  security_group_ids = concat(var.security_group_ids, [aws_security_group.dsf_web_console_sg.id])
  iam_actions        = local.iam_actions
  key_pair           = var.key_pair
  attach_public_ip   = var.attach_public_ip
  instance_readiness_params = {
    commands = local.readiness_commands
    enable   = true
    timeout  = local.timeout
  }
}
