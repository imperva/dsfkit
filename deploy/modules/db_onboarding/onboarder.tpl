#!/bin/bash -x
set -e
TMPDIR=$(mktemp -u)
mkdir -p ./$TMPDIR
trap "rm -rf ./$TMPDIR" EXIT

scp -o StrictHostKeyChecking="no" -i ${ssh_key_path} ${module_path}/artifacts/generate_token.sh ec2-user@${dsf_hub_address}:generate_token.sh
ssh -o StrictHostKeyChecking="no" -i ${ssh_key_path} ec2-user@${dsf_hub_address} -C "chmod +x ./generate_token.sh && ./generate_token.sh" > ./$TMPDIR/hub_token
hub_token=$(cat ./$TMPDIR/hub_token)
# echo token: $hub_token

# Run oboarder jar
JAR=$(ls ${module_path}/artifacts/sonar_onboarder-*.jar | tail -1)
JDK=jdk-16.0.2_linux-x64_bin.tar.gz
JDK_BUCKET=1ef8de27-ed95-40ff-8c08-7969fc1b7901

if command -v java &> /dev/null; then
    # echo java -jar $JAR ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
    java -jar $JAR ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
else
    echo "java is not installed on the workstation."
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "Please install java and run again." # For overcming the lack of java, we need the have AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY defined
        exit 1
    else
        set -x
        . ${module_path}/artifacts/s3get.sh
        s3get $JDK_BUCKET/$JDK > ./$TMPDIR/$JDK
        tar -xvf ${module_path}/artifacts/unzip.tar -C ./$TMPDIR
        PATH=$PATH:$PWD/$TMPDIR tar zxvf ./$TMPDIR/$JDK -C ./$TMPDIR
        JAVA_TOP_LEVEL_DIR=$(tar tzf ./$TMPDIR/$JDK | sed -e 's@/.*@@' | uniq)
        ./$TMPDIR/$JAVA_TOP_LEVEL_DIR/bin/java -jar $JAR ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
    fi
fi
