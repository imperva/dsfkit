locals {
  database_installation_commands = {
    PostgreSql = <<-EOF
          apt install postgresql -y
          systemctl start postgresql.service        
          echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | psql &>/dev/null' | crontab -u postgres -
        EOF
    MySql      = <<-EOF
          apt install mysql-server -y
          systemctl start mysql.service
          echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | mysql &>/dev/null' | crontab -
        EOF
    MariaDB    = <<-EOF
          apt install mariadb-server -y
          sed -i '/ProtectSystem/d' /usr/lib/systemd/system/mariadb.service
          systemctl daemon-reload
          systemctl restart mariadb.service
          echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | mariadb --socket=/run/mysqld/mysqld.sock &>/dev/null' | crontab -
        EOF
  }

  user_data = <<-EOF
      #!/bin/bash
      set -x
      set -e

      apt update -y
      echo "Installing database:"
      ${local.database_installation_commands[var.db_type]}
      apt install awscli -y
      echo "Downloading agent:"
      aws s3 cp s3://${var.binaries_location.s3_bucket}/${var.binaries_location.s3_key} .
      chmod +x ./${var.binaries_location.s3_key}
      echo "Installing agent:"
      ./${var.binaries_location.s3_key} -n
      rm ${var.binaries_location.s3_key}
      echo "Registering agent:"
      /usr/imperva/ragent/bin/cli --dcfg /usr/imperva/ragent/etc --dtarget /usr/imperva/ragent/etc --dlog /usr/imperva/ragent/etc/logs/cli registration advanced-register registration-type=Primary is-db-agent=true tunnel-protocol=TCP gw-ip=${var.registration_params.agent_gateway_host} gw-port=443 manual-settings-activation=Automatic monitor-network-channels=Both password="${var.registration_params.secure_password}" ragent-name="${join("-", [var.friendly_name, "db", "with", "agent"])}" site='${var.registration_params.site}' server-group="${var.registration_params.server_group}";
      echo "Starting agent:"
      /usr/imperva/ragent/bin/rainit start;
      EOF
}