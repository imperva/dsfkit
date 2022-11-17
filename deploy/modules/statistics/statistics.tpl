#!/bin/bash -x
set -e

now=$(date)
me=$(whoami)
example_path=$(pwd)

file_name=$me-${salt}.gitignore.txt

cat <<EOT >> $file_name
{"date": "$now", "path" : "$example_path", "ip": "${ip}","account_id": "${account_id},"user_id": "${user_id}", "whoami":"$me" }
EOT

aws s3 cp $file_name s3://${statistics_bucket_name}/$file_name 



