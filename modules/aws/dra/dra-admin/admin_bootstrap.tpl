#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
my_nameserver=$(ifconfig eth0 | grep "inet " | awk '{print $2}')
my_ip=$(ifconfig eth0 | grep "inet " | awk '{print $2}')
my_default_gw=$(ip route show | grep default | awk '{print $3}')
my_cidr=$(awk -F. '{                                     
    split($0, octets)
    for (i in octets) {
        mask += 8 - log(2**8 - octets[i])/log(2);
    }
    print mask
}' <<< $(ifconfig eth0 | grep "inet " | awk '{print $4}'))

sudo su
export ITP_HOME=/opt/itp
export CATALINA_HOME=/opt/apache-tomcat
chmod +x /opt/itp_global_conf/auto_deploy.sh
sed -i 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
password=$(/usr/local/bin/aws secretsmanager get-secret-value --secret-id ${admin_analytics_registration_password_secret_arn} --query SecretString --output text)
/opt/itp_global_conf/auto_deploy.sh --hostname "$(hostname)" --ip-address "$my_ip" --dns-servers "$my_nameserver" --registration-password "$password" --cidr "$my_cidr" --default-gateway "$my_default_gw" --machine-type "Admin"