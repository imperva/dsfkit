locals {
  bastion_host = try(var.proxy_info.ip_address, null)
  # bastion_host        = var.attach_persistent_public_ip ? aws_eip.dsf_instance_eip[0].public_ip : try(var.proxy_info.ip_address, null)
  bastion_private_key = try(file(var.proxy_info.private_ssh_key_path), "")
  bastion_user        = try(var.proxy_info.ssh_user, null)

  instance_address = var.use_public_ip ? local.public_ip : local.private_ip
  display_name     = var.name

  script_path = var.terraform_script_path_folder == null ? null : (join("/", [var.terraform_script_path_folder, "terraform_%RAND%.sh"]))
  install_script = templatefile("${path.module}/setup.tftpl", {
    resource_type                       = var.resource_type
    installation_s3_bucket              = var.binaries_location.s3_bucket
    installation_s3_region              = var.binaries_location.s3_region
    installation_s3_key                 = var.binaries_location.s3_key
    display_name                        = local.display_name
    admin_password_secret               = local.admin_password_secret_name
    secadmin_password_secret            = local.secadmin_password_secret_name
    sonarg_password_secret              = local.sonarg_password_secret_name
    sonargd_password_secret             = local.sonargd_password_secret_name
    hub_sonarw_public_key               = var.resource_type == "agentless-gw" ? var.hub_sonarw_public_key : ""
    main_node_sonarw_public_key         = local.main_node_sonarw_public_key
    main_node_sonarw_private_key_secret = local.sonarw_secret_aws_name
    jsonar_uuid                         = random_uuid.jsonar_uuid.result
    additional_install_parameters       = var.additional_install_parameters
    access_tokens_array                 = local.access_tokens_array
  })
}

resource "random_uuid" "jsonar_uuid" {}

module "statistics" {
  source          = "../../../modules/aws/statistics"
  deployment_name = var.name
  product         = "SONAR"
  resource_type   = var.resource_type
  artifact        = "s3://${sha256(var.binaries_location.s3_bucket)}/${var.binaries_location.s3_key}"
}

resource "null_resource" "readiness" {
  count = var.skip_instance_health_verification == true ? 0 : 1
  connection {
    type        = "ssh"
    user        = local.ami_username
    private_key = file(var.ssh_key_path)
    host        = local.instance_address

    timeout = "5m"

    bastion_host        = local.bastion_host
    bastion_private_key = local.bastion_private_key
    bastion_user        = local.bastion_user

    script_path = local.script_path
  }

  provisioner "remote-exec" {
    inline = [
      "if ! sudo timeout 900 cloud-init status --wait | grep done &>/dev/null; then",
      "  cat /var/log/cloud-init-output.log;",
      "  echo;",
      "  sudo cloud-init status;",
      "  exit 1;",
      "fi"
    ]
  }

  triggers = {
    instance_id = aws_instance.dsf_base_instance.id
  }

  depends_on = [
    aws_eip_association.eip_assoc,
    module.statistics
  ]
}

module "statistics_success" {
  source = "../../../modules/aws/statistics"

  id         = module.statistics.id
  status     = "success"
  depends_on = [null_resource.readiness]
}
