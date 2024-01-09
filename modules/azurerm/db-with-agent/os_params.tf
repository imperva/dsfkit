locals {
  os_params = {
    "Ubuntu" : {
      vm_image = {
        publisher = "canonical"
        offer     = "0001-com-ubuntu-pro-focal"
        sku       = "pro-20_04-lts"
        version   = "latest"
      }
      vm_user                = "adminuser"
      agent_installation_dir = "/usr/imperva",
      package_install        = <<-EOF
        while sudo lsof /var/lib/apt/lists/lock; do
            echo "Waiting for the lock to be released..."
            sleep 1
        done
        sudo apt update -y
      EOF
      database_installation_commands = {
        PostgreSql = <<-EOF
          command -v psql || sudo apt install postgresql -y
          if ! sudo systemctl is-active --quiet postgresql; then
              sudo systemctl start postgresql.service
              echo "PostgreSQL service started successfully."
          else
              echo "PostgreSQL service is already running. Skipping start."
          fi
        EOF
        MySql      = <<-EOF
          command -v mysql || sudo apt install mysql-server -y
          if ! sudo systemctl is-active --quiet mysql; then
              sudo systemctl start mysql.service
              echo "MySQL service started successfully."
          else
              echo "MySQL service is already running. Skipping start."
          fi
        EOF
        #        MariaDB    = <<-EOF
        #          command -v mariadb || sudo apt install mariadb-server -y
        #          sed -i '/ProtectSystem/d' /usr/lib/systemd/system/mariadb.service
        #          if ! sudo systemctl is-active --quiet mariadb; then
        #              sudo systemctl daemon-reload
        #              sudo systemctl restart mariadb.service
        #              echo "MariaDB service started successfully."
        #          else
        #              echo "MariaDB service is already running. Skipping start."
        #          fi
        #        EOF
      }
      database_queries_commands = {
        PostgreSql = <<-EOF
          echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | psql &>/dev/null' | sudo crontab -u postgres -
        EOF
        MySql      = <<-EOF
          echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | mysql &>/dev/null' | crontab -
        EOF
        #        MariaDB    = <<-EOF
        #          echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | mariadb --socket=/run/mysqld/mysqld.sock &>/dev/null' | crontab -
        #        EOF
      }
    }
  }
}