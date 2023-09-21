locals {
  dra_association_commands = [for dra_admin in var.dra_details : <<-EOF
    curl --silent --insecure --max-time 10000 -X POST -G 'https://127.0.0.1:8443/register-to-dra' -d adminIpOrHostname=${dra_admin.address} -d adminRegistrationPassword=${dra_admin.password} -d adminReportingServer=true -d analyticsArchiveUsername=${dra_admin.username} -d analyticsArchivePassword=${dra_admin.password} -d resumeDraJobs=true --header "Authorization: Bearer ${module.hub_instance.access_tokens.usc.token}"
    EOF
  ]
}

resource "null_resource" "dra_association" {
  count = length(local.dra_association_commands) > 0 ? 1 : 0
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
    inline = concat(local.dra_association_commands)
  }
  depends_on = [
    module.hub_instance.ready
  ]
  triggers = {
    command = join("", local.dra_association_commands)
  }
}
