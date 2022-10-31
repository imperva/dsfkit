
#################################
# Run HADR scripts
#################################
resource "null_resource" "exec_hadr" {
  provisioner "local-exec" {
    command         = templatefile("${path.module}/hadr.tpl", {
    dsf_hub_primary_public_ip     = var.dsf_hub_primary_public_ip
    dsf_hub_primary_private_ip    = var.dsf_hub_primary_private_ip
    dsf_hub_secondary_public_ip   = var.dsf_hub_secondary_public_ip
    dsf_hub_secondary_private_ip  = var.dsf_hub_secondary_private_ip
    ssh_key_path                  = var.ssh_key_path
  })
    interpreter     = ["/bin/bash", "-c"]
  }
}
