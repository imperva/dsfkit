locals {
  cm_association_log_path_in_hub = "/tmp/dsfkit_cm_association.log"

  cm_payload = var.cm_details == null ? null : jsonencode({
    data = {
      cm_name                  = var.cm_details.name
      hostname                 = var.cm_details.hostname
      port                     = var.cm_details.port
      auth_method              = var.cm_details.registration_method
      ddc_active_node_hostname = var.cm_details.ddc_connection_hostname
      ddc_active_node_port     = var.cm_details.ddc_connection_port
      username                 = var.cm_details.username
      password                 = var.cm_details.password
      registration_token       = var.cm_details.registration_token
      is_load_balancer         = var.cm_details.is_load_balancer
      ddc_enabled              = var.cm_details.ddc_enabled
    }
  })

  cm_association_commands = var.cm_details == null ? "" : <<-EOF
    #!/bin/bash
    exec > ${local.cm_association_log_path_in_hub} 2>&1
    set -e
    response=$(curl -k -s -w "\n%%{http_code}" -X POST 'https://127.0.0.1:8443/integrations/api/v1/ciphertrust' --header "Content-Type: application/json" --header "Authorization: Bearer ${module.hub_instance.access_tokens.usc.token}" --data '${replace(local.cm_payload, "'", "'\\''")}')
    BODY=$(echo "$response" | sed '$d')
    STATUS=$(echo "$response" | tail -n1)
    if [ "$STATUS" -ge 200 ] && [ "$STATUS" -lt 300 ]; then
      echo "CipherTrust Manager successfully associated with the DSF Hub."
    else
      echo "Request failed with HTTP status $STATUS"
      echo "$BODY"
      exit 1
    fi
    EOF
}

resource "null_resource" "cm_association" {
  count = var.cm_details != null ? 1 : 0
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

  provisioner "local-exec" {
    command = "echo 'Starting association of CipherTrust Manager with the DSF Hub. Logs will be written on the DSF Hub machine at ${local.cm_association_log_path_in_hub}'"
  }
  provisioner "remote-exec" {
    inline = concat([local.cm_association_commands])
  }
  depends_on = [
    module.hub_instance.ready
  ]
  triggers = {
    command = local.cm_association_commands
  }
}
