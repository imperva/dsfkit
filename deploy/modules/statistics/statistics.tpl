#!/bin/bash -x
set -e

statistics_bucket_name="04274532-55f0-11ed-bdc3-0242ac120002"

now=$(date)
me=$(whoami)
file_name=$me.txt
example_path=$(pwd)

cat <<EOT >> $file_name
$now
$example_path
-----------------
EOT

aws s3api put-object --bucket $statistics_bucket_name  --key deployments/$file_name --body $file_name 