#!/bin/bash
# upgrade_v4_10.sh
# Note: This script must not contain an apostrophe, since its contents are wrapped by apostrophes when run
set -e
#set -x
set -u

# Redirect stderr to stdout
exec 2>&1

echo "Running as user: $(whoami)"
echo "Running in directory: $(pwd)"

# This check is needed since if the tee command below throws an error, it does not cause the script to exit,
# probably since it is a complex command and the error gets "swallowed"
if [ ! -w "/var/log" ]; then
    echo "No write access to /var/log/ directory, cannot write upgrade log, exiting..."
    exit 1
fi
exec > >(tee /var/log/upgrade.log) 2>&1

installation_s3_bucket="$1"
installation_s3_key="$2"
installation_s3_region="$3"

#installation_s3_bucket="1ef8de27-ed95-40ff-8c08-7969fc1b7901"
#installation_s3_key="jsonar-4.12.0.10.0.tar.gz"
#installation_s3_region="us-east-1"

TARBALL_FILE=$(basename ${installation_s3_key})

STATE_DIR=/imperva
APPS_DIR=$STATE_DIR/apps

function download_tarball() {
    if [ -e ./$TARBALL_FILE ]; then
      echo "Tarball file already exists on disk"
    else
      echo "Downloading tarball ${installation_s3_key} in bucket ${installation_s3_bucket} in region ${installation_s3_region}"
      /usr/local/bin/aws s3 cp s3://${installation_s3_bucket}/${installation_s3_key} ./$TARBALL_FILE --region ${installation_s3_region} >/dev/null
    fi
}

#function extract_tarball() {
#    echo Extracting tarball..
#    sudo tar -xf ./$TARBALL_FILE -gz -C $APPS_DIR
#    rm ./$TARBALL_FILE
#    sudo chown -R sonarw:sonar $APPS_DIR
#}
#
#function unsetEnvironmentVariables() {
#    unset JSONAR_LOCALDIR JSONAR_BASEDIR JSONAR_VERSION JSONAR_DATADIR JSONAR_LOGDIR
#}
#
#function runSonargSetup() {
#    sudo $APPS_DIR/jsonar/apps/4.12.0.10.0/bin/sonarg-setup --no-interactive
#}

function run_upgrade() {
     pwd
#    download_tarball
#    extract_tarball
#    unsetEnvironmentVariables
#    runSonargSetup
}

run_upgrade