locals {
  ssh_options         = "-o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  bastion_host        = var.proxy_info.proxy_address
  bastion_private_key = try(file(var.proxy_info.proxy_ssh_key_path), "")
  bastion_user        = var.proxy_info.proxy_ssh_user

  public_ip        = length(aws_eip.dsf_instance_eip) > 0 ? aws_eip.dsf_instance_eip[0].public_ip : null
  private_ip       = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null
  instance_address = var.use_public_ip ? local.public_ip : local.private_ip
  display_name     = "DSF-${var.resource_type}-${var.name}"

  script_path = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))
  install_script = templatefile("${path.module}/setup.tpl", {
    resource_type                          = var.resource_type
    installation_s3_bucket                 = var.binaries_location.s3_bucket
    installation_s3_key                    = var.binaries_location.s3_key
    display-name                           = local.display_name
    password_secret                        = aws_secretsmanager_secret.password_secret.name
    ssh_key_path                           = var.ssh_key_path
    hub_sonarw_public_key                  = var.resource_type == "gw" ? var.hub_sonarw_public_key : ""
    primary_node_sonarw_public_key         = local.primary_node_sonarw_public_key
    primary_node_sonarw_private_key_secret = local.sonarw_secret_aws_name
    public_fqdn                            = var.use_public_ip ? "True" : ""
    uuid                                   = random_uuid.uuid.result
    additional_install_parameters          = var.additional_install_parameters
  })
}

data "aws_region" "current" {}

resource "random_uuid" "uuid" {}

resource "null_resource" "wait_for_installation_completion" {
  count = var.skip_instance_health_verification == true ? 0 : 1
  connection {
    type        = "ssh"
    user        = local.ami_username
    private_key = file(var.ssh_key_path)
    host        = local.instance_address

    timeout = "1m"

    bastion_host        = local.bastion_host
    bastion_private_key = local.bastion_private_key
    bastion_user        = local.bastion_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = [
      "if ! sudo timeout 900 cloud-init status --wait | grep done &>/dev/null; then",
      "  cat /var/log/user-data.log;",
      "  echo;",
      "  sudo cloud-init status;",
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
