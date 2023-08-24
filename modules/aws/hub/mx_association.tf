locals {
  bastion_host        = try(var.hub_proxy_info.ip_address, null)
  bastion_private_key = try(file(var.hub_proxy_info.private_ssh_key_path), "")
  bastion_user        = try(var.hub_proxy_info.ssh_user, null)
  script_path         = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))

  hub_address = var.use_public_ip ? module.hub_instance.public_ip : module.hub_instance.private_ip
  mx_association_commands = [for mx in var.mx_details : <<-EOF
    curl --fail -k -X POST 'https://127.0.0.1:8443/usc/api/v2/appliances' --header "Authorization: Bearer ${module.hub_instance.access_tokens.usc.token}" -F 'applianceDtoApiData={"data":{"type":"MX","name":"${mx.name}","hostOrIp":"${mx.address}","mxUsername":"${mx.username}","mxPassword":"${mx.password}", "hasCertificate":false, "mxAuthType": "PASSWORD"}};type=application/json' || curl --fail -k -X POST 'https://127.0.0.1:8443/usc/api/internal/appliances' --header "Authorization: Bearer ${module.hub_instance.access_tokens.usc.token}" -F 'applianceDtoApiData={"data":{"type":"MX","name":"${mx.name}","hostOrIp":"${mx.address}","mxUsername":"${mx.username}","mxPassword":"${mx.password}", "hasCertificate":false, "mxAuthType": "PASSWORD"}};type=application/json'
    EOF
  ]
}

resource "null_resource" "mx_association" {
  count = length(local.mx_association_commands) > 0 ? 1 : 0
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
    inline = concat(local.mx_association_commands)
  }
  depends_on = [
    module.hub_instance.ready
  ]
  triggers = {
    command = join("", local.mx_association_commands)
  }
}
