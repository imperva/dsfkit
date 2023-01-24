#!/bin/bash -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -e

sudo su

yum -y install git

yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
yum -y install unzip
unzip awscliv2.zip
./aws/install
export PATH=$PATH:/usr/local/bin

yum -y install wget

pwd

wget https://github.com/imperva/dsfkit/raw/1.3.5/examples/${example_type}/${example_name}/${example_name}.zip
unzip ${example_name}.zip
cd ${example_name}

export AWS_ACCESS_KEY_ID=${access_key}
export AWS_SECRET_ACCESS_KEY=${secret_key}
export AWS_REGION=${region}

terraform init
terraform apply -auto-approve -var='web_console_cidr=${web_console_cidr}'
