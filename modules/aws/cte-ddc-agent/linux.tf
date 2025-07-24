locals {
  cte_agent_inline_commands_linux = var.agent_installation.cte_agent_installation_file != null ? [
    "sudo yum install lsof -y",
    "sudo chmod +x ${basename(var.agent_installation.cte_agent_installation_file)}",
    "sudo ./${basename(var.agent_installation.cte_agent_installation_file)} -i -y",
    "sudo /opt/vormetric/DataSecurityExpert/agent/vmd/bin/register_host silent ${local.reg_params_template_name}"
  ] : []
  ddc_agent_inline_commands_linux = var.agent_installation.ddc_agent_installation_file != null ? [
    "set -xe",
    "sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm",
    "sudo yum install libxml2 libgsasl openssl libcurl libuuid protobuf krb5-libs libaio libnsl -y",
    "sudo rpm -ivh ${basename(var.agent_installation.ddc_agent_installation_file)}",
    "sudo er2-config -i ${var.cipher_trust_manager_address}",
    "sudo er2-config -t",
    "sudo /etc/init.d/er2-agent restart"
  ] : []
  reboot_inline_commands_linux = [
    "echo 'Attempting to schedule reboot using systemd-run...'",
    # This command creates a temporary systemd service that will run /sbin/reboot after 10 seconds.
    # The 10-second delay gives Terraform enough time to register the successful execution of
    # systemd-run and disconnect gracefully before the actual reboot begins. Otherwise, the SSH connection between
    # Terraform and the instance will be interrupted during execution, which will cause the Terraform run to fail.
    "sudo systemd-run --on-active=10 --unit=terraform-reboot-service /sbin/reboot",
    "echo 'Reboot command scheduled. Terraform will now proceed.'",
    "sleep 2" # A small additional pause to ensure full detachment.
  ]
}

