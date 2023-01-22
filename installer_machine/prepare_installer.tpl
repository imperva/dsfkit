#!/bin/bash -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -e

sudo su

yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
yum -y install unzip
unzip awscliv2.zip
./aws/install
export PATH=$PATH:/usr/local/bin

Need to wget the example, not the zip

wget https://github.com/imperva/dsfkit/raw/1.3.4/installer_machine/installer_machine.zip
unzip installer_machine.zip
cd dsfkit/examples/${example_path}

export AWS_ACCESS_KEY_ID=${access_key}
export AWS_SECRET_ACCESS_KEY=${secret_key}
export AWS_REGION=${region}

terraform init
terraform apply -auto-approve -var='web_console_cidr=[${web_console_cidr}]'
