locals {
  # we are using one password for all services and we have one DRA only
  admin_password            = var.dra_details == null ? "" : urlencode(var.dra_details.password)
  archiver_password         = var.dra_details == null ? "" : urlencode(var.dra_details.archiver_password)
  admin_username            = var.dra_details == null ? "" : var.dra_details.username
  admin_address             = var.dra_details == null ? "" : var.dra_details.address
  dra_association_commands  = var.dra_details == null ? "" : <<-EOF
    curl -k --max-time 10000 -X POST -G 'https://127.0.0.1:8443/register-to-dra' -d adminIpOrHostname=${local.admin_address} -d adminRegistrationPassword=${local.admin_password} -d adminReportingServer=true -d analyticsArchiveUsername=${local.admin_username} -d analyticsArchivePassword=${local.archiver_password} -d resumeDraJobs=true --header "Authorization: Bearer ${module.hub_instance.access_tokens["archiver"].token}"
    EOF
}

resource "null_resource" "dra_association" {
  count = var.dra_details != null ? 1 : 0

  connection {
    type        = "ssh"
    user        = module.hub_instance.ssh_user
    private_key = file(var.ssh_key_pair.ssh_private_key_file_path)
    host        = var.use_public_ip ? module.hub_instance.public_ip : module.hub_instance.private_ip

    bastion_host        = local.bastion_host
    bastion_private_key = local.bastion_private_key
    bastion_user        = local.bastion_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = concat([local.dra_association_commands])
  }
  depends_on = [
    module.hub_instance.ready
  ]
  triggers = {
    key = local.dra_association_commands
  }
}
