
#################################
# Run HADR scripts
#################################
data "template_file" "hadr" {
  template = file("${path.module}/hadr.tpl")
  vars = {
    dsf_hub_primary_public_ip     = var.dsf_hub_primary_public_ip
    dsf_hub_primary_private_ip    = var.dsf_hub_primary_private_ip
    dsf_hub_secondary_public_ip   = var.dsf_hub_secondary_public_ip
    dsf_hub_secondary_private_ip  = var.dsf_hub_secondary_private_ip
    ssh_key_path                  = var.ssh_key_path
  }
}

resource "null_resource" "exec_hadr" {
  provisioner "local-exec" {
    command         = "${data.template_file.hadr.rendered}"
    interpreter     = ["/bin/bash", "-c"]
  }
}
