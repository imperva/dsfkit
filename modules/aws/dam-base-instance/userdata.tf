locals {
  # permit_root_ssh_login_commands = [
  #   "sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config",
  #   "sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
  #   "echo '+:root:ALL' > /etc/security/access.conf",
  #   "echo Barbapapa12# | passwd --stdin root",
  #   "systemctl restart sshd"
  # ]
  display_name = aws_instance.dsf_base_instance.tags.Name

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

data "aws_region" "current" {}

module "statistics" {
  source          = "../../../modules/aws/statistics"
  deployment_name = var.name
  product         = "DAM"
  resource_type   = var.resource_type
  artifact        = join("@", compact(["ami://${sha256(data.aws_ami.selected-ami.image_id)}", var.ami != null ? null : var.dam_version]))
}

resource "null_resource" "readiness" {
  count = var.instance_readiness_params.enable == true ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOF
    TIMEOUT=${var.instance_readiness_params.timeout}
    START=$(date +%s)

    operation() {
      ${var.instance_readiness_params.commands}
    }

    # Perform the operation in a loop until the timeout is reached
    while true; do
      # Check if the timeout has been reached
      NOW=$(date +%s)
      ELAPSED=$((NOW-START))
      if [ $ELAPSED -gt $TIMEOUT ]; then
        echo "Timeout reached. To obtain additional information, refer to the /var/log/ec2_auto_ftl.log file located on the remote server."
        exit 1
      fi

      operation

      sleep 60
    done
    EOF
  }

  triggers = {
    instance_id = aws_instance.dsf_base_instance.id
    commands    = var.instance_readiness_params.commands
  }
  depends_on = [module.statistics]
}

module "statistics_success" {
  source = "../../../modules/aws/statistics"

  id         = module.statistics.id
  status     = "success"
  depends_on = [null_resource.readiness]
}
