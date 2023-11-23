locals {
  display_name     = var.name

#  userdata = <<-EOF
#    ${var.user_data_commands}
#  EOF
}
#
#module "statistics" {
#  source = "../../../modules/aws/statistics"
#  count  = var.send_usage_statistics ? 1 : 0
#
#  deployment_name = var.name
#  product         = "DAM"
#  resource_type   = var.resource_type
#  artifact        = join("@", compact(["ami://${sha256(data.aws_ami.selected-ami.image_id)}", var.ami != null ? null : var.dam_version]))
#}
#
#resource "null_resource" "readiness" {
#  count = var.instance_readiness_params.enable == true ? 1 : 0
#  provisioner "local-exec" {
#    interpreter = ["bash", "-c"]
#    command     = <<-EOF
#    TIMEOUT=${var.instance_readiness_params.timeout}
#    START=$(date +%s)
#
#    operation() {
#      ${var.instance_readiness_params.commands}
#    }
#
#    # Perform the operation in a loop until the timeout is reached
#    while true; do
#      # Check if the timeout has been reached
#      NOW=$(date +%s)
#      ELAPSED=$((NOW-START))
#      if [ $ELAPSED -gt $TIMEOUT ]; then
#        echo "Timeout reached. To obtain additional information, refer to the /var/log/ec2_auto_ftl.log file located on the remote server."
#        exit 1
#      fi
#
#      operation
#
#      sleep 60
#    done
#    EOF
#  }
#
#  triggers = {
#    instance_id = aws_instance.dsf_base_instance.id
#    commands    = var.instance_readiness_params.commands
#  }
#  depends_on = [module.statistics]
#}
#
#module "statistics_success" {
#  source = "../../../modules/aws/statistics"
#  count  = var.send_usage_statistics ? 1 : 0
#
#  id         = module.statistics[0].id
#  status     = "success"
#  depends_on = [null_resource.readiness]
#}
