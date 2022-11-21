#!/bin/bash -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -e

sudo su
yum -y install git

yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform

git clone https://github.com/imperva/dsfkit.git
cd /dsfkit/deploy/examples/${example_name}

export AWS_ACCESS_KEY_ID=${access_key}
export AWS_SECRET_ACCESS_KEY=${secret_key}
export AWS_REGION=${region}

terraform init
terraform apply -auto-approve -var='web_console_cidr=["${web_console_cidr}"]'
