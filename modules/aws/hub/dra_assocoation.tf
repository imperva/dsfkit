locals {
  host                      = var.use_public_ip ? module.hub_instance.public_ip : module.hub_instance.private_ip
  # we are using one password for all services and we have one DRA only
  admin_password            = length(var.dra_details) == 0 ? "" : urlencode(var.dra_details.password)
  archiver_password         = length(var.dra_details) == 0 ? "" : urlencode(var.dra_details.archiver_password)
  dra_association_commands  = <<-EOT
    curl -k --max-time 10000 -X POST -G 'https://${local.host}:8443/register-to-dra' -d adminIpOrHostname=${var.dra_details.address} -d adminRegistrationPassword=${local.admin_password} -d adminReportingServer=true -d analyticsArchiveUsername=${var.dra_details.username} -d analyticsArchivePassword=${local.archiver_password} -d resumeDraJobs=true --header "Authorization: Bearer ${module.hub_instance.access_tokens["dam-to-hub"].token}"
    EOT
}

resource "null_resource" "dra_association" {
  count = length(local.dra_association_commands) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = local.dra_association_commands
  }
  depends_on = [
    module.hub_instance.ready
  ]
  triggers = {
    key = local.dra_association_commands
  }
}
