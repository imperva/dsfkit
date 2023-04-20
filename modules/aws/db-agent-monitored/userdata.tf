locals {
    user_data = <<-EOF
      #!/bin/bash
      set -x

      echo "Registering agent:"
      /usr/imperva/ragent/bin/cli --dcfg /usr/imperva/ragent/etc --dtarget /usr/imperva/ragent/etc --dlog /usr/imperva/ragent/etc/logs/cli registration advanced-register registration-type=Primary is-db-agent=true tunnel-protocol=TCP gw-ip=${var.agent_gateway_host} gw-port=443 manual-settings-activation=Automatic monitor-network-channels=Both password="${var.secure_password}" ragent-name="${join("-", [var.friendly_name, "db", "with", "agent"])}" site='${var.site}' server-group="${var.server_group}";
      echo "Starting agent:"
      /usr/imperva/ragent/bin/rainit start;
      echo "Creating postgresql periodic query cron job:"
      echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | psql &>/dev/null' | crontab -u postgres -
      EOF
}