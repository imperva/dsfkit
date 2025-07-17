locals {
  enable_ldt = 0
  enable_fam = 1

  reg_params_template_name = "cte_agent_reg_params.tftpl"

  bastion_host        = try(var.ingress_communication_via_proxy.proxy_address, null)
  bastion_private_key = try(file(var.ingress_communication_via_proxy.proxy_private_ssh_key_path), "")
  bastion_user        = try(var.ingress_communication_via_proxy.proxy_ssh_user, null)
  script_path         = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))

  public_ip        = var.attach_persistent_public_ip ? aws_eip.dsf_instance_eip[0].public_ip : aws_instance.cte_ddc_agent.public_ip
  public_dns       = var.attach_persistent_public_ip ? aws_eip.dsf_instance_eip[0].public_dns : aws_instance.cte_ddc_agent.public_dns
  private_ip       = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null
  instance_address = var.use_public_ip ? local.public_ip : local.private_ip

  security_group_ids = concat(
    [for sg in aws_security_group.dsf_agent_sg : sg.id],
  var.security_group_ids)

  # Determine the values based on the OS type
  ami_id                    = var.os_type == "Windows" ? data.aws_ami.agent_ami_windows[0].id : data.aws_ami.agent_ami_linux[0].id
  user_data                 = var.os_type == "Windows" ? local.user_data_windows : null
  reboot_commands           = var.os_type == "Windows" ? local.reboot_inline_commands_windows : local.reboot_inline_commands_linux
  ddc_agent_inline_commands = var.os_type == "Windows" ? local.ddc_agent_inline_commands_windows : local.ddc_agent_inline_commands_linux
  cte_agent_inline_commands = var.os_type == "Windows" ? local.cte_agent_inline_commands_windows : local.cte_agent_inline_commands_linux
  target_platform           = var.os_type == "Windows" ? "windows" : null

  dummy_file_path = "${path.module}/dummy.txt"
}

resource "aws_eip" "dsf_instance_eip" {
  count  = var.attach_persistent_public_ip ? 1 : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = var.friendly_name })
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.attach_persistent_public_ip ? 1 : 0
  instance_id   = aws_instance.cte_ddc_agent.id
  allocation_id = aws_eip.dsf_instance_eip[0].id
}

resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
  tags            = var.tags
}

resource "aws_instance" "cte_ddc_agent" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_pair.ssh_public_key_name
  user_data     = local.user_data
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags        = merge(var.tags, { Name : var.friendly_name })
  volume_tags = merge(var.tags, { Name : var.friendly_name })
  depends_on  = [aws_eip.dsf_instance_eip]

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "null_resource" "cte_ddc_copy_file" {
  provisioner "file" {
    source      = var.agent_installation.install_cte ? var.agent_installation.cte_agent_installation_file : local.dummy_file_path
    destination = basename(var.agent_installation.install_cte ? var.agent_installation.cte_agent_installation_file : local.dummy_file_path)
  }

  provisioner "file" {
    content = var.agent_installation.install_cte ? templatefile("${path.module}/${local.reg_params_template_name}", {
      server_hostname    = var.cipher_trust_manager_address
      registration_token = var.agent_installation.registration_token
      enable_ldt         = local.enable_ldt
      enable_fam         = local.enable_fam
    }) : ""
    destination = var.agent_installation.install_cte ? local.reg_params_template_name : basename(local.dummy_file_path)
  }

  provisioner "remote-exec" {
    inline = var.agent_installation.install_cte ? local.cte_agent_inline_commands : ["echo 'No CTE agent installation required'"]
  }

  provisioner "file" {
    source      = var.agent_installation.install_ddc ? var.agent_installation.ddc_agent_installation_file : local.dummy_file_path
    destination = basename(var.agent_installation.install_ddc ? var.agent_installation.ddc_agent_installation_file : local.dummy_file_path)
  }

  provisioner "remote-exec" {
    inline = var.agent_installation.install_ddc ? local.ddc_agent_inline_commands : ["echo 'No DDC agent installation required'"]
  }

  # reboot the host to activate the FAM feature
  provisioner "remote-exec" {
    inline = local.reboot_commands
  }

  connection {
    type            = "ssh"
    user            = local.agent_ami_ssh_user
    private_key     = file(var.ssh_key_pair.ssh_private_key_file_path)
    host            = local.instance_address
    target_platform = local.target_platform

    bastion_host        = local.bastion_host
    bastion_private_key = local.bastion_private_key
    bastion_user        = local.bastion_user

    script_path = local.script_path
  }
  depends_on = [aws_instance.cte_ddc_agent, aws_eip_association.eip_assoc]
}
