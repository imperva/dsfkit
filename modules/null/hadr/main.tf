locals {
  main_ssh_key_path = var.ssh_key_path
  ssh_key_path_dr   = var.ssh_key_path_dr != null ? var.ssh_key_path_dr : var.ssh_key_path
  main_ssh_user     = var.ssh_user
  dr_ssh_user       = var.ssh_user_dr != null ? var.ssh_user_dr : var.ssh_user
  script_path       = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))
}

#################################
# Run HADR scripts
#################################
resource "null_resource" "exec_hadr_main" {
  connection {
    type        = "ssh"
    user        = local.main_ssh_user
    private_key = file(local.main_ssh_key_path)
    host        = var.dsf_main_ip

    timeout = "5m"

    bastion_host        = var.proxy_info.proxy_address
    bastion_private_key = try(file(var.proxy_info.proxy_private_ssh_key_path), "")
    bastion_user        = var.proxy_info.proxy_ssh_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = ["sudo $JSONAR_BASEDIR/bin/arbiter-setup setup-2hadr-replica-set --ipv4-address-main=${var.dsf_main_private_ip} --ipv4-address-dr=${var.dsf_dr_private_ip} --replication-sync-interval=30"]
  }
}

resource "null_resource" "exec_hadr_dr" {
  connection {
    type        = "ssh"
    user        = local.dr_ssh_user
    private_key = file(local.ssh_key_path_dr)
    host        = var.dsf_dr_ip

    timeout = "5m"

    bastion_host        = var.proxy_info.proxy_address
    bastion_private_key = try(file(var.proxy_info.proxy_private_ssh_key_path), "")
    bastion_user        = var.proxy_info.proxy_ssh_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = ["sudo $JSONAR_BASEDIR/bin/arbiter-setup restart-secondary-services --disable-primary-check"]
  }

  depends_on = [
    null_resource.exec_hadr_main
  ]
}

resource "time_sleep" "sleep_before_replication_cycle" {
  create_duration = "1m"
  depends_on = [
    null_resource.exec_hadr_dr
  ]
}

resource "null_resource" "exec_replication_cycle_on_dr" {
  connection {
    type        = "ssh"
    user        = local.dr_ssh_user
    private_key = file(local.ssh_key_path_dr)
    host        = var.dsf_dr_ip

    timeout = "5m"

    bastion_host        = var.proxy_info.proxy_address
    bastion_private_key = try(file(var.proxy_info.proxy_private_ssh_key_path), "")
    bastion_user        = var.proxy_info.proxy_ssh_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = [
      "sudo touch $JSONAR_LOGDIR/sonarw/replication.log",
      "sudo chown sonarw:sonar $JSONAR_LOGDIR/sonarw/replication.log",
    "sudo $JSONAR_BASEDIR/bin/arbiter-setup run-replication --no-tail"]
  }

  depends_on = [
    time_sleep.sleep_before_replication_cycle
  ]
}

resource "time_sleep" "sleep_before_hadr_verify" {
  create_duration = "10m"
  depends_on = [
    null_resource.exec_replication_cycle_on_dr
  ]
}

resource "null_resource" "hadr_verify" {
  connection {
    type        = "ssh"
    user        = local.main_ssh_user
    private_key = file(local.main_ssh_key_path)
    host        = var.dsf_main_ip

    timeout = "5m"

    bastion_host        = var.proxy_info.proxy_address
    bastion_private_key = try(file(var.proxy_info.proxy_private_ssh_key_path), "")
    bastion_user        = var.proxy_info.proxy_ssh_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = ["sudo $JSONAR_BASEDIR/bin/arbiter-setup check-2hadr-replica-set"]
  }

  depends_on = [
    time_sleep.sleep_before_hadr_verify
  ]
}
