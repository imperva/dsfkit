locals {
  host                      = var.use_public_ip ? module.hub_instance.public_ip : module.hub_instance.private_ip
  password                  = urlencode(var.dra_details[0].password) # we are using one password for all services
  dra_association_commands  = [for dra_admin in var.dra_details : <<-EOT
    curl --silent --insecure --max-time 10000 -X POST -G 'https://${local.host}:8443/register-to-dra' -d adminIpOrHostname=${dra_admin.address} -d adminRegistrationPassword=${local.password} -d adminReportingServer=true -d analyticsArchiveUsername=${dra_admin.username} -d analyticsArchivePassword=${local.password} -d resumeDraJobs=true --header "Authorization: Bearer ${module.hub_instance.access_tokens["dam-to-hub"].token}"
    EOT
  ]
}

resource "null_resource" "dra_association" {
  count = length(local.dra_association_commands) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = local.dra_association_commands[0]
  }
  depends_on = [
    module.hub_instance.ready
  ]
  triggers = {
    key = join("", local.dra_association_commands)
  }
}
