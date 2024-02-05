locals {
  os_params = {
    "Red Hat" : {
      ami_owner              = "309956199498"
      ami_name               = "RHEL-8.6.0_HVM-2022*-x86_64-2-Hourly2-GP2"
      ami_ssh_user           = "ec2-user"
      agent_installation_dir = "/opt/imperva",
      installation_filename = "Imperva-ragent-RHEL-v8-kSMP-px86_64-b14.6.0.60.0.637577.bsx"
      package_install = <<-EOF
        yum update -y
        yum install unzip -y
      EOF
      database_installation_commands = {
        PostgreSql = <<-EOF
          yum install @postgresql -y
          /usr/bin/postgresql-setup --initdb
          systemctl start postgresql.service        
          echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | psql &>/dev/null' | crontab -u postgres -
        EOF
        MySql      = <<-EOF
          dnf -y install @mysql
          systemctl enable mysqld.service
          systemctl start mysqld.service
          echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | mysql &>/dev/null' | crontab -
        EOF
        MariaDB    = <<-EOF
          yum install mariadb-server -y
          #sed -i '/ProtectSystem/d' /usr/lib/systemd/system/mariadb.service
          #systemctl daemon-reload
          systemctl restart mariadb.service
          echo '* * * * * for i in $(seq 1 500); do echo "select * from dummy;"; done  | mysql &>/dev/null' | crontab -
        EOF
      }
    },
    "Ubuntu" : {
      ami_owner              = "099720109477" # Amazon
      ami_name               = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      ami_ssh_user           = "ubuntu"
      agent_installation_dir = "/usr/imperva",
      installation_filename = "Imperva-ragent-UBN-px86_64-b14.6.0.60.0.636085.bsx"
      package_install = <<-EOF
        apt update -y
        apt install unzip
      EOF
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
    }
  }
}