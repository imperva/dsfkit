locals {
  # permit_root_ssh_login_commands = [
  #   "sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config",
  #   "sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
  #   "echo '+:root:ALL' > /etc/security/access.conf",
  #   "echo Barbapapa12# | passwd --stdin root",
  #   "systemctl restart sshd"
  # ]
  commands = jsonencode({
    "commands" : var.user_data_commands
    }
  )
  userdata = <<-EOF
    WaitHandle : none
    StackId : none
    Region : ${data.aws_region.current.name}
    IsTerraform : true
    SecurePassword : ${local.encrypted_secure_password}
    MxPassword : ${local.encrypted_mx_password}
    KMSKeyRegion : ${data.aws_region.current.name}
    ProductRole : ${local.mapper.product_role[var.resource_type]}
    AssetTag : ${var.dam_model}
    GatewayMode : dam
    ProductLicensing : BYOL
    MetaData : ${local.commands}
    RegistrationParams : {"StackName" : "${var.name}","StackId" : "${var.name}","SQSName" : "","Region" : "${data.aws_region.current.name}","AccessKey" : "","SecretKey" : ""}
  EOF
}

resource "null_resource" "readiness" {
  count = var.instance_readiness_params.enable == true ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOF
      ${var.instance_readiness_params.commands}
    EOF
  }
  triggers = {
    instance_id = aws_instance.dsf_base_instance.id
    commands    = var.instance_readiness_params.commands
  }
}