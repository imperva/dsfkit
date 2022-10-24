resource "time_sleep" "wait_120_seconds" {
  create_duration = "120s"
}

#################################
# Federation script
#################################

data "template_file" "lock" {
  # template = file("${path.module}/job_serializer.sh")
  template = file("${path.module}/grab_lock.sh")
  vars = {
    index = var.index
  }
}

data "template_file" "federate_hub" {
  template = file("${path.module}/federate_hub.tpl")
  vars = {
    ssh_key_path        = var.hub_ssh_key_path
    dsf_gw_ip           = var.gw
    dsf_hub_ip          = var.hub
  }
}

data "template_file" "federate_gw" {
  template = file("${path.module}/federate_gw.tpl")
  vars = {
    ssh_key_path        = var.hub_ssh_key_path
    dsf_gw_ip           = var.gw
    dsf_hub_ip          = var.hub
  }
}

resource "null_resource" "federate_cmds" {
  provisioner "local-exec" {
    command         = "${data.template_file.lock.rendered} ${data.template_file.federate_hub.rendered} ${data.template_file.federate_gw.rendered}"
    interpreter     = ["/bin/bash", "-c"]
  }
  depends_on = [
    time_sleep.wait_120_seconds,
  ]
  triggers = {
    installation_source = "${var.installation_source}",
  }
}
