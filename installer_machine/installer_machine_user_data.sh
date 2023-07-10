#!/bin/bash -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -e

sudo su

yum -y install git

yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform-1.4.5

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
yum -y install unzip
unzip awscliv2.zip
./aws/install
export PATH=$PATH:/usr/local/bin

yum -y install wget

yum -y install jq

pwd
