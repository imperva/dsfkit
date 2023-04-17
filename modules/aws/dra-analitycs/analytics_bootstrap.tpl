#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
echo BEGIN
function wait-for-admin(){
  while ! nc -z ${admin_server_ip} 8443; do
    sleep 0.1
  done
}
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
export ITPBA_HOME=/opt/itpba
export CATALINA_HOME=/opt/apache-tomcat
chmod +x /opt/itp_global_conf/auto_deploy.sh
wait-for-admin
/opt/itp_global_conf/auto_deploy.sh --hostname "$(hostname)" --ip-address "$my_ip" --dns-servers "$my_nameserver" --registration-password "${registration_password}" --cidr "$my_cidr" --default-gateway "$my_default_gw" --machine-type "Analytics" --analytics-user "${analytics_user}" --analytics-password "${analytics_password}" --admin-server-ip "${admin_server_ip}"
wait-for-admin

