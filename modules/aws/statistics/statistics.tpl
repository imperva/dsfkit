#!/bin/bash -x
set -e

if [[ "$(aws --version)" == *"aws-cli"* ]]
then
  now=$(date '+%Y-%m-%d %H:%M:%S')
  me=$(whoami)
  example_path=$(pwd)

  # Include epoch seconds in file name to differentiate between different terraform runs in the same machine
  file_name=$me-`date +%s`.gitignore.txt

  cat <<EOT >> $file_name
{"date": "$now", "path": "$example_path", "ip": "${ip}", "account_id": "${account_id}", "user_id": "${user_id}", "whoami": "$me", "user_arn": "${user_arn}", "terraform_workspace": "${terraform_workspace}"}
EOT

  aws s3 cp $file_name s3://${statistics_bucket_name}/$file_name
  rm $file_name
else
  echo "Statistics won't be sent to Imperva - AWS CLI is not installed on your machine"
  exit 0
fi



