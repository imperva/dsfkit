#!/bin/bash
set -e
# set -x
TMPDIR=$(mktemp -u)
mkdir -p ./$TMPDIR
trap "rm -rf ./$TMPDIR" EXIT

function profile_to_access_keys() {
    INI_FILE=~/.aws/credentials

    while IFS=' = ' read key value
    do
        if [[ $key == \[*] ]]; then
            section=$key
        elif [[ $value ]] && [[ $section == '['"$${AWS_PROFILE:-default}"']' ]]; then
            if [[ $key == 'aws_access_key_id' ]]; then
                AWS_ACCESS_KEY_ID=$value
            elif [[ $key == 'aws_secret_access_key' ]]; then
                AWS_SECRET_ACCESS_KEY=$value
            fi
        fi
    done < $INI_FILE

    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        echo $AWS_ACCESS_KEY_ID
        echo $AWS_SECRET_ACCESS_KEY
    fi
}

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    access_keys=$(profile_to_access_keys)
    export AWS_ACCESS_KEY_ID=$(echo "$access_keys" | head -1)
    export AWS_SECRET_ACCESS_KEY=$(echo "$access_keys" | tail -1)
    unset AWS_PROFILE
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "Failed to discover aws access keys. Please approach our Slack channel for help - #edsf-auto-deployment-public"
        exit 1
    fi
fi

scp -o StrictHostKeyChecking="no" -i ${ssh_key_path} ${module_path}/artifacts/generate_token.sh ec2-user@${dsf_hub_address}:generate_token.sh
ssh -o StrictHostKeyChecking="no" -i ${ssh_key_path} ec2-user@${dsf_hub_address} -C "chmod +x ./generate_token.sh && ./generate_token.sh" > ./$TMPDIR/hub_token
hub_token=$(cat ./$TMPDIR/hub_token)
# echo token: $hub_token

# Run oboarder jar
JAR_NAME=sonar_onboarder
ARTIFACTS_BUCKET=${onboarder_jar_bucket}
JAR_KEY=$(aws s3 ls s3://$ARTIFACTS_BUCKET | sort | grep $JAR_NAME | tail -1 | awk '{print $NF}')
. ${module_path}/artifacts/s3get.sh
s3get $ARTIFACTS_BUCKET/$JAR_KEY > ./$TMPDIR/$JAR_KEY

if command -v java &> /dev/null; then
    # java -jar ./$TMPDIR/$JAR_KEY ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
    java -jar ./$TMPDIR/$JAR_KEY ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
else
    echo "java is not installed on the workstation."
    JDK_NAME=jdk-16
    JDK_KEY=$(aws s3 ls s3://$ARTIFACTS_BUCKET | sort | grep $JDK_NAME | tail -1 | awk '{print $NF}')
    s3get $ARTIFACTS_BUCKET/$JDK_KEY > ./$TMPDIR/$JDK_KEY
    tar -xvf ${module_path}/artifacts/unzip.tar -C ./$TMPDIR
    PATH=$PATH:$PWD/$TMPDIR tar zxvf ./$TMPDIR/$JDK_KEY -C ./$TMPDIR
    JAVA_TOP_LEVEL_DIR=$(tar tzf ./$TMPDIR/$JDK_KEY | sed -e 's@/.*@@' | uniq)
    ./$TMPDIR/$JAVA_TOP_LEVEL_DIR/bin/java -jar $TMPDIR/$JAR_KEY ${db_arn} ${dsf_hub_address} $hub_token ${assignee_gw} ${db_user} ${db_password}
fi
