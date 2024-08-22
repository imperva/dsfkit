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
installation_s3_region="$1"
installation_s3_key="$2"
echo "Tarball file name: ${installation_s3_key}, in bucket: ${installation_s3_bucket}, in region: ${installation_s3_region}"

# For example: /imperva/apps/jsonar/apps/4.11.0.0.0
JSONAR_BASEDIR=$(grep "^JSONAR_BASEDIR=" /etc/sysconfig/jsonar | cut -d"=" -f2)
JSONAR_VERSION=$(grep "^JSONAR_VERSION=" /etc/sysconfig/jsonar | cut -d"=" -f2)
echo "Current Sonar version ${JSONAR_VERSION}"

# For example, /imperva/apps
EXTRACTION_BASE_DIR=$(echo "$JSONAR_BASEDIR" | sed "s|/jsonar/apps/${JSONAR_VERSION}||")

TARBALL_FILE_NAME=$(basename ${installation_s3_key})
TARBALL_FILE=$EXTRACTION_BASE_DIR/$TARBALL_FILE_NAME

VERSION="${TARBALL_FILE#*-}"
VERSION="${VERSION%.tar.gz}"
VERSION="${VERSION%_*}"  # remove any date suffix
echo "Version: $VERSION"

EXTRACTION_DIR="${EXTRACTION_BASE_DIR}/jsonar/apps/${VERSION}"
echo "Tarball extraction base directory: ${EXTRACTION_BASE_DIR}"
echo "Tarball extraction directory: $EXTRACTION_DIR"

function extract_tarball() {
    echo "Extracting tarball..."
    sudo tar -xf $TARBALL_FILE_NAME -gz -C $EXTRACTION_BASE_DIR
    sudo chown -R sonarw:sonar $EXTRACTION_DIR
    echo "Extracting tarball completed"
}

function download_and_extract_tarball() {
    if [ -e $EXTRACTION_DIR ]; then
        echo "Tarball file is already extracted"
    elif [ -e $TARBALL_FILE_NAME ]; then
        echo "Tarball file already exists on disk"
        extract_tarball
        rm $TARBALL_FILE_NAME
    else
      echo "Downloading tarball to $(pwd) .. (using aws cli)"
      /usr/local/bin/aws s3 cp s3://${installation_s3_bucket}/${installation_s3_key} $TARBALL_FILE_NAME --region ${installation_s3_region} >/dev/null
      echo "Downloading tarball completed"
      extract_tarball
      rm $TARBALL_FILE_NAME
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
