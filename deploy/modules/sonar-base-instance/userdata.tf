locals {
  ssh_options = "-o ConnectionAttempts=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  proxy_arg = var.proxy_address == null ? "" : "-o ProxyCommand='ssh ${local.ssh_options} -i ${var.ssh_key_pair_path} -W %h:%p ec2-user@${var.proxy_address}'"
  public_ip = length(aws_eip.dsf_instance_eip) > 0 ? aws_eip.dsf_instance_eip[0].public_ip : null
  private_ip = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null
  instance_address = var.public_ip ? local.public_ip : local.private_ip
  display_name = "DSF-${var.dsf_type}-${var.name}"

  install_script = templatefile("${path.module}/install.tpl", {
    dsf_type                            = var.dsf_type
    installation_s3_bucket              = var.installation_location.s3_bucket
    installation_s3_key                 = var.installation_location.s3_key
    display-name                        = local.display_name
    admin_password                      = var.admin_password
    secadmin_password                   = var.admin_password
    sonarg_pasword                      = var.admin_password
    sonargd_pasword                     = var.admin_password
    dsf_hub_sonarw_private_ssh_key_name = "dsf_hub_federation_private_key_${var.name}"
    dsf_hub_sonarw_public_ssh_key_name  = "dsf_hub_federation_public_key_${var.name}"
    ssh_key_pair_path                   = var.ssh_key_pair_path
    sonarw_public_key                   = var.sonarw_public_key
    sonarw_secret_name                  = var.sonarw_secret_name
    public_fqdn                         = var.proxy_address != null ? "" : "True"
    uuid                                = random_uuid.uuid.result
    additional_install_parameters       = var.additional_install_parameters
  })
}

resource "random_uuid" "uuid" {}

resource "null_resource" "wait_for_installation_completion" {
  provisioner "local-exec" {
    command     = "sleep 20; ssh ${local.ssh_options} ${local.proxy_arg} -i ${var.ssh_key_pair_path} ec2-user@${local.instance_address} 'if ! cloud-init status --wait | grep done &>/dev/null; then cat /var/log/user-data.log; fi; cloud-init status'"
    interpreter = ["/bin/bash", "-c"]
  }
  triggers = {
    installation_file = aws_instance.dsf_base_instance.arn
  }
  depends_on = [
    aws_instance.dsf_base_instance
  ]
}