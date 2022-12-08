locals {
  ssh_options         = "-o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  bastion_host        = var.proxy_address
  bastion_private_key = try(file(var.proxy_private_key), "")
  bastion_user        = "ec2-user"

  public_ip        = length(aws_eip.dsf_instance_eip) > 0 ? aws_eip.dsf_instance_eip[0].public_ip : null
  private_ip       = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null
  instance_address = var.public_ip ? local.public_ip : local.private_ip
  display_name     = "DSF-${var.resource_type}-${var.name}"

  sonar_secret_region = var.sonarw_secret_region != null ? var.sonarw_secret_region : data.aws_region.current.name

  install_script = templatefile("${path.module}/setup.tpl", {
    resource_type                       = var.resource_type
    installation_s3_bucket              = var.installation_location.s3_bucket
    installation_s3_key                 = var.installation_location.s3_key
    display-name                        = local.display_name
    admin_password                      = var.admin_password
    secadmin_password                   = var.admin_password
    sonarg_pasword                      = var.admin_password
    sonargd_pasword                     = var.admin_password
    dsf_hub_sonarw_private_ssh_key_name = "dsf_hub_federation_private_key_${var.name}"
    dsf_hub_sonarw_public_ssh_key_name  = "dsf_hub_federation_public_key_${var.name}"
    ssh_key_path                        = var.ssh_key_path
    sonarw_public_key                   = var.sonarw_public_key
    sonarw_secret_name                  = var.sonarw_secret_name
    public_fqdn                         = var.proxy_address != null ? "" : "True"
    uuid                                = random_uuid.uuid.result
    additional_install_parameters       = var.additional_install_parameters
    sonar_secret_region                 = local.sonar_secret_region
  })
}

data "aws_region" "current" {}

resource "random_uuid" "uuid" {}

resource "null_resource" "wait_for_installation_completion" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.ssh_key_path)
    host        = local.instance_address

    timeout = "15m"

    bastion_host        = local.bastion_host
    bastion_private_key = local.bastion_private_key
    bastion_user        = local.bastion_user
  }


  #   connection {
  #   type        = "ssh"
  #   user        = "ec2-user"
  #   private_key = file(local.private_key)
  #   host        = "10.0.2.49"

  #   timeout = "15m"

  #   bastion_host        = "13.42.107.150"
  #   bastion_private_key = file(local.bastion_private_key)
  #   bastion_user        = "ec2-user"
  # }

  provisioner "remote-exec" {
    inline = [
      # "sleep 60",
      "if ! timeout 600 cloud-init status --wait | grep done &>/dev/null; then",
      "  cat /var/log/user-data.log;",
      "  echo;",
      "  cloud-init status;",
      "  exit 1;",
      "fi"
    ]
  }

  triggers = {
    installation_file = aws_instance.dsf_base_instance.arn
  }

  depends_on = [
    aws_instance.dsf_base_instance,
    aws_security_group_rule.sg_cidr_ingress
  ]
}
