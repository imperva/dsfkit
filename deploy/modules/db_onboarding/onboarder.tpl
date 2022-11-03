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
JAR_NAME=sonar_onboarder
JAR_BUCKET=${onboarder_jar_bucket}
JAR_KEY=$(aws s3 ls s3://$JAR_BUCKET | sort | grep $JAR_NAME | tail -1 | awk '{print $NF}')
. ${module_path}/artifacts/s3get.sh
s3get $JAR_BUCKET/$JAR_KEY > ./$TMPDIR/$JAR_KEY

if command -v java &> /dev/null; then
    # java -jar ./$TMPDIR/$JAR_KEY ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
    java -jar ./$TMPDIR/$JAR_KEY ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
else
    echo "java is not installed on the workstation."
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "Please install java and run again." # For overcming the lack of java, we need the have AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY defined
        exit 1
    else
        set -x
        JDK_NAME=jdk-16
        JDK_KEY=$(aws s3 ls s3://$JAR_BUCKET | sort | grep $JDK_NAME | tail -1 | awk '{print $NF}')
        s3get $JAR_BUCKET/$JDK_KEY > ./$TMPDIR/$JDK_KEY
        tar -xvf ${module_path}/artifacts/unzip.tar -C ./$TMPDIR
        PATH=$PATH:$PWD/$TMPDIR tar zxvf ./$TMPDIR/$JDK_KEY -C ./$TMPDIR
        JAVA_TOP_LEVEL_DIR=$(tar tzf ./$TMPDIR/$JDK_KEY | sed -e 's@/.*@@' | uniq)
        ./$TMPDIR/$JAVA_TOP_LEVEL_DIR/bin/java -jar $JAR_KEY ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
    fi
fi
