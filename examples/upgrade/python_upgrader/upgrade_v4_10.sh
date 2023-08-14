#!/bin/bash
# upgrade_v4_10.sh: Upgrades DSF Hub or Agentless Gateway nodes which version (source version) is 4.10 and up
# Note: This script must not contain an apostrophe, since its contents are wrapped by apostrophes when run
set -e
#set -x
set -u

# Redirect stderr to stdout
exec 2>&1

# This check is needed since if the tee command below throws an error, it does not cause the script to exit,
# probably since it is a complex command and the error gets "swallowed"
if [ ! -w "/var/log" ]; then
    echo "No write access to /var/log/ directory, cannot write upgrade log, exiting..."
    exit 1
fi
exec > >(tee -a /var/log/upgrade.log) 2>&1

echo -e "\n-----------------------------------------------------------"
echo "Running upgrade bash script at $(date)"

cd /root

echo "Running as user: $(whoami)"
echo "Running in directory: $(pwd)"

# starting the argument count from 0 since this script is run by "bash -c"
installation_s3_bucket="$0"
installation_s3_key="$1"
installation_s3_region="$2"
echo "Tarball file name: ${installation_s3_key}, in bucket: ${installation_s3_bucket}, in region: ${installation_s3_region}"

#installation_s3_bucket="1ef8de27-ed95-40ff-8c08-7969fc1b7901"
#installation_s3_key="jsonar-4.12.0.10.0.tar.gz"
#installation_s3_region="us-east-1"

TARBALL_FILE=$(basename ${installation_s3_key})

JSONAR_BASEDIR=$(grep "^JSONAR_BASEDIR=" /etc/sysconfig/jsonar | cut -d"=" -f2)
# In deployments by eDSF Kit, the value is /imperva
STATE_DIR=$(echo "$JSONAR_BASEDIR" | sed "s|/apps/jsonar/apps.*||")
echo "State directory: ${STATE_DIR}"
APPS_DIR=$STATE_DIR/apps

VERSION="${TARBALL_FILE#*-}"
VERSION="${VERSION%.tar.gz}"
echo "Version: $VERSION"

EXTRACTION_DIR="${APPS_DIR}/jsonar/apps/${VERSION}"
echo "Tarball extraction directory: $EXTRACTION_DIR"

function extract_tarball() {
    echo "Extracting tarball..."
    sudo tar -xf ./$TARBALL_FILE -gz -C $APPS_DIR
    sudo chown -R sonarw:sonar $APPS_DIR
    echo "Extracting tarball completed"
}

function download_and_extract_tarball() {
    if [ -e $EXTRACTION_DIR ]; then
        echo "Tarball file is already extracted"
    elif [ -e ./$TARBALL_FILE ]; then
        echo "Tarball file already exists on disk"
        extract_tarball
        rm ./$TARBALL_FILE
    else
      echo "Downloading tarball..."
      /usr/local/bin/aws s3 cp s3://${installation_s3_bucket}/${installation_s3_key} ./$TARBALL_FILE --region ${installation_s3_region} >/dev/null
      echo "Downloading tarball completed"
      extract_tarball
      rm ./$TARBALL_FILE
    fi
}

function unset_environment_variables() {
    unset JSONAR_LOCALDIR JSONAR_BASEDIR JSONAR_VERSION JSONAR_DATADIR JSONAR_LOGDIR
    echo "Environment variables were unset"
}

function run_sonarg_setup() {
    sudo $EXTRACTION_DIR/bin/sonarg-setup --no-interactive
}

function run_upgrade() {
    download_and_extract_tarball
    unset_environment_variables
    run_sonarg_setup
}

run_upgrade

echo "Upgrade bash script completed at $(date)"
echo "-------------------------------------------------------------"
