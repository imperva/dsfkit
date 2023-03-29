locals {
  ami_username = "ec2-user"

  secure_password           = var.password
  mx_password               = var.password
  encrypted_secure_password = chomp(aws_kms_ciphertext.encrypted_secure_password.ciphertext_blob)
  encrypted_mx_password     = chomp(aws_kms_ciphertext.encrypted_mx_password.ciphertext_blob)

  timezone = "UTC"

  license_passphrase = random_password.pass.result
  encrypted_license  = data.external.encrypted_license.result.cipher_text
}

data "aws_region" "current" {}

locals {
  large_scale_mode = false
  user_data_commands = [
    "/opt/SecureSphere/etc/ec2/ec2_auto_ftl --init_mode  --user=${local.ami_username} --serverPassword=%mxPassword% --secure_password=%securePassword% --system_password=%securePassword% --timezone=${local.timezone} --time_servers=default --dns_servers=default --dns_domain=default --management_interface=eth0 --check_server_status --initiate_services --encLic=${local.encrypted_license} --passPhrase=${local.license_passphrase}"
  ]
  iam_actions = [
    "ec2:DescribeInstances"
  ]
}

module "mx" {
  source           = "../../../modules/aws/dam-base-instance"
  name             = join("-", [var.friendly_name, "mx"])
  ses_model        = "AVM150"
  attach_public_ip = true
  imperva_password = local.mx_password
  secure_password  = local.secure_password
  ports = {
    tcp = [443, 514, 2812, 8081, 8083, 8084, 8085]
    udp = []
  }
  resource_type      = "mx"
  subnet_id          = var.subnet_id
  web_console_cidr   = var.web_console_cidr
  user_data_commands = local.user_data_commands
  sg_ingress_cidr    = var.sg_ingress_cidr
  sg_ssh_cidr        = var.sg_ssh_cidr
  iam_actions        = local.iam_actions
  key_pair           = var.key_pair
  encrypted_license = {
    cipher_text = local.encrypted_license
    passphrase  = local.license_passphrase
  }
}
