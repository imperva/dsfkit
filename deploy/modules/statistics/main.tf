#################################
# Run Statistics scripts
#################################
# locals {
#   statistics_cmds = templatefile("${path.module}/statistics.tpl", {
#     dsf_hub_primary_public_ip     = var.dsf_hub_primary_public_ip
#     dsf_hub_primary_private_ip    = var.dsf_hub_primary_private_ip
#     dsf_hub_secondary_public_ip   = var.dsf_hub_secondary_public_ip
#     dsf_hub_secondary_private_ip  = var.dsf_hub_secondary_private_ip
#     ssh_key_path                  = var.ssh_key_path
#   }
#   )
# }

# resource "null_resource" "exec_hadr" {
#   provisioner "local-exec" {
#     command         = local.statistics_cmds
#     interpreter     = ["/bin/bash", "-c"]
#   }
# }