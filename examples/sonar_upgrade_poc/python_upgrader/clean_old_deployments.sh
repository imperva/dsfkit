#!/bin/bash
# clean_old_deployments.sh: Cleans old deployment directories on DSF Hub or Agentless Gateway nodes
# Note: This script must not contain an apostrophe, since its contents are wrapped by apostrophes when run
set -e
#set -x
set -u

# Redirect stderr to stdout
exec 2>&1

# This check is needed since if the tee command below throws an error, it does not cause the script to exit,
# probably since it is a complex command and the error gets "swallowed"
#if [ ! -w "/var/log" ]; then
#    echo "No write access to /var/log/ directory, cannot write clean_old_deployments log, exiting..."
#    exit 1
#fi
#exec > >(tee -a /var/log/clean_old_deployments.log) 2>&1

echo -e "\n-----------------------------------------------------------"
echo "Running clean old deployments bash script at $(date)"

#cd /root

#echo "Running as user: $(whoami)"
#echo "Running in directory: $(pwd)"


#JSONAR_BASEDIR=$(grep "^JSONAR_BASEDIR=" /etc/sysconfig/jsonar | cut -d"=" -f2)
## In deployments by eDSF Kit, the value is /imperva
#STATE_DIR=$(echo "$JSONAR_BASEDIR" | sed "s|/apps/jsonar/apps.*||")
#echo "State directory: ${STATE_DIR}"
#APPS_DIR=$STATE_DIR/apps

#EXTRACTION_DIR="${APPS_DIR}/jsonar/apps/${VERSION}"
#echo "Tarball extraction directory: $EXTRACTION_DIR"


#function run_sonarg_setup() {
##    sudo $EXTRACTION_DIR/bin/sonarg-setup clean-old-deployments --no-interactive
#}
#
#run_sonarg_setup
echo "Skipping clean old deployments..."

echo "Clean old deployments bash script completed at $(date)"
echo "-------------------------------------------------------------"
