#!/bin/bash -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -e


sudo yum -y install git

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform

sudo git clone https://github.com/imperva/dsfkit.git
cd /dsfkit/deploy/examples/${example_name}

export AWS_ACCESS_KEY_ID=${access_key}
export AWS_SECRET_ACCESS_KEY=${secret_key}
export AWS_REGION=${region}

sudo terraform init
sudo terraform apply -auto-approve -var='web_console_cidr=["${web_console_cidr}"]'