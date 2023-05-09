locals {
  agent_installation_dir = local.os_params[local.os_type].agent_installation_dir
  user_data              = <<-EOF
      #!/bin/bash
      set -x
      set -e
      ${local.os_params[local.os_type].package_install}
      echo "Installing database:"
      ${local.os_params[local.os_type].database_installation_commands[local.db_type]}
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      export PATH=$PATH:/usr/local/bin:/usr/local/bin
      echo "Downloading agent:"
      aws s3 cp s3://${local.binaries_location.s3_bucket}/${local.binaries_location.s3_key} .
      chmod +x ./${local.binaries_location.s3_key}
      echo "Installing agent:"
      ./${local.binaries_location.s3_key} -n -d ${local.agent_installation_dir}
      rm ${local.binaries_location.s3_key}
      echo "Registering agent:"
      ${local.agent_installation_dir}/ragent/bin/cli --dcfg ${local.agent_installation_dir}/ragent/etc --dtarget ${local.agent_installation_dir}/ragent/etc --dlog ${local.agent_installation_dir}/ragent/etc/logs/cli registration advanced-register registration-type=Primary is-db-agent=true tunnel-protocol=TCP gw-ip=${var.registration_params.agent_gateway_host} gw-port=443 manual-settings-activation=Automatic monitor-network-channels=Both password="${var.registration_params.secure_password}" ragent-name="${join("-", [var.friendly_name, "db", "with", "agent"])}" site='${var.registration_params.site}' server-group="${var.registration_params.server_group}";
      echo "Starting agent:"
      ${local.agent_installation_dir}/ragent/bin/rainit start;
      EOF
}