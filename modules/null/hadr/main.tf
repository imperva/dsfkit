locals {
  primary_ssh_key_path   = var.ssh_key_path
  ssh_key_path_secondary = var.ssh_key_path_secondary != null ? var.ssh_key_path_secondary : var.ssh_key_path
  primary_ssh_user       = var.ssh_user
  secondary_ssh_user     = var.ssh_user_secondary != null ? var.ssh_user_secondary : var.ssh_user
}

#################################
# Run HADR scripts
#################################
resource "null_resource" "exec_hadr_primary" {
  connection {
    type        = "ssh"
    user        = local.primary_ssh_user
    private_key = file(local.primary_ssh_key_path)
    host        = var.dsf_hub_primary_public_ip

    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = ["sudo $JSONAR_BASEDIR/bin/arbiter-setup setup-2hadr-replica-set --ipv4-address-main=${var.dsf_hub_primary_private_ip} --ipv4-address-dr=${var.dsf_hub_secondary_private_ip} --replication-sync-interval=1"]
  }
}

resource "null_resource" "exec_hadr_secondary" {
  connection {
    type        = "ssh"
    user        = local.secondary_ssh_user
    private_key = file(local.ssh_key_path_secondary)
    host        = var.dsf_hub_secondary_public_ip

    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = ["sudo $JSONAR_BASEDIR/bin/arbiter-setup restart-secondary-services"]
  }

  depends_on = [
    null_resource.exec_hadr_primary
  ]
}

resource "time_sleep" "sleep" {
  create_duration = "120s"
  depends_on = [
    null_resource.exec_hadr_secondary
  ]
}

resource "null_resource" "hadr_verify" {
  connection {
    type        = "ssh"
    user        = local.primary_ssh_user
    private_key = file(local.primary_ssh_key_path)
    host        = var.dsf_hub_primary_public_ip

    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = ["sudo $JSONAR_BASEDIR/bin/arbiter-setup check-2hadr-replica-set"]
  }

  depends_on = [
    time_sleep.sleep
  ]
}
