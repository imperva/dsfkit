#!/bin/bash -x
set -e

scp -o StrictHostKeyChecking="no" -i ${ssh_key_path} ${module_path}/artifacts/generate_token.sh ec2-user@${dsf_hub_address}:generate_token.sh
ssh -o StrictHostKeyChecking="no" -i ${ssh_key_path} ec2-user@${dsf_hub_address} -C "chmod +x ./generate_token.sh && ./generate_token.sh" > hub_token
hub_token=$(cat hub_token)
echo token: $hub_token

# Run oboarder jar
JAR=${module_path}/artifacts/sonar_onboarder-1.4.2-SNAPSHOT-all.jar
JDK=jdk-16.0.2_linux-x64_bin.tar.gz
JDK_BUCKET=1ef8de27-ed95-40ff-8c08-7969fc1b7901

if command -v java &> /dev/null; then
    java -jar $JAR ${db_arn} ${dsf_hub_address} $hub_token ${hub_role_arn} ${assignee_gw} ${db_user} ${db_password}
else
    echo "jave is not installed on the workstation. Copying jar to hub and run it from there"
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "For overcming the lack of java problem, we need the have AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY defined"
        exit 1
    else
        . ${module_path}/artifacts/s3get.sh
        s3get $JDK_BUCKET/$JDK > $JDK
        set -x
        tar -xvf ${module_path}artifacts/unzip.tar
        PATH=$PATH:$PWD tar zxvf $JAR
        ./jdk-16.0.2/bin/java -jar $JAR ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
    fi
fi
