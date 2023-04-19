locals {
    db_type = "PostgreSql"
    site = "Default%20Site"
    server_group = "${var.friendly_name}-server-group"
    db_serivce = "${var.friendly_name}-db"
    user_data = <<-EOF
      #!/bin/bash
      set -x
      
      echo "Login to mx:"
      curl -k --request POST 'https://${var.management_server_host_for_api_access}:8083/SecureSphere/api/v1/auth/session' --header 'Authorization: Basic ${base64encode("admin:${var.mx_password}")}' -c cookiefile
      echo "Creating security groups:"
      until curl -k --request POST 'https://${var.management_server_host_for_api_access}:8083/SecureSphere/api/v1/conf/serverGroups/${local.site}/${local.server_group}' -b cookiefile | grep "IMP-10005"; do
      sleep 10;
      done
      echo "Creating db services:"
      curl -k --request POST 'https://${var.management_server_host_for_api_access}:8083/SecureSphere/api/v1/conf/dbServices/${local.site}/${local.server_group}/${local.db_serivce}' \
      --header 'Content-Type: application/json' \
      --data-raw '{
          "db-service-type": "${local.db_type}"
      }' -b cookiefile
      echo "Registering agent:"
      /usr/imperva/ragent/bin/cli --dcfg /usr/imperva/ragent/etc --dtarget /usr/imperva/ragent/etc --dlog /usr/imperva/ragent/etc/logs/cli registration advanced-register registration-type=Primary is-db-agent=true tunnel-protocol=TCP gw-ip=${var.agent_gateway_host} gw-port=443 manual-settings-activation=Automatic monitor-network-channels=Both password="${var.secure_password}" ragent-name="${join("-", [var.friendly_name, "db", "with", "agent"])}" site='Default Site' server-group="${local.server_group}";
      echo "Starting agent:"
      /usr/imperva/ragent/bin/rainit start;
      echo "Creating postgresql periodic query cron job:"
      echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | psql &>/dev/null' | crontab -u postgres -
      EOF
}