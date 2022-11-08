locals {
  ssh_options = "-o ConnectionAttempts=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  proxy_arg = var.proxy_address == null ? "" : "-o ProxyCommand='ssh ${local.ssh_options} -i ${var.ssh_key_pair_path} -W %h:%p ec2-user@${var.proxy_address}'"
  install_script = templatefile("${path.module}/install.tpl", {
    dsf_type                            = var.dsf_type
    installation_s3_bucket              = var.installation_location.s3_bucket
    installation_s3_key                 = var.installation_location.s3_key
    display-name                        = "DSF-${var.dsf_type}-${var.name}"
    admin_password                      = var.admin_password
    secadmin_password                   = var.admin_password
    sonarg_pasword                      = var.admin_password
    sonargd_pasword                     = var.admin_password
    dsf_hub_sonarw_private_ssh_key_name = "dsf_hub_federation_private_key_${var.name}"
    dsf_hub_sonarw_public_ssh_key_name  = "dsf_hub_federation_public_key_${var.name}"
    ssh_key_pair_path                   = var.ssh_key_pair_path
    sonarw_public_key                   = var.sonarw_public_key
    sonarw_secret_name                  = var.sonarw_secret_name
    instance_fqdn                       = var.instance_address
  })
}

#################################
# Hub install script (AKA userdata)
#################################

resource "null_resource" "install_sonar" {
  provisioner "local-exec" {
    command     = "ssh ${local.ssh_options} ${local.proxy_arg} -i ${var.ssh_key_pair_path} ec2-user@${var.instance_address} '${nonsensitive(local.install_script)}'"
    interpreter = ["/bin/bash", "-c"]
  }
  triggers = {
    installation_file = join("", [var.installation_location.s3_bucket, var.installation_location.s3_key])
  }
}

resource "null_resource" "extract_jsonar_uid" {
  provisioner "local-exec" {
    command     = "ssh ${local.ssh_options} ${local.proxy_arg} -i ${var.ssh_key_pair_path} ec2-user@${var.instance_address} 'echo -n $JSONAR_UID' > tmp-${var.instance_address}-${terraform.workspace}-jsonar-uid"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [
    null_resource.install_sonar
  ]
  triggers = {
    always_run = "${timestamp()}" # Run only when isntallation path has changed
  }
}

data "local_file" "jsonar_uid" {
  filename = "tmp-${var.instance_address}-${terraform.workspace}-jsonar-uid"
  depends_on = [
    resource.null_resource.extract_jsonar_uid
  ]
}
