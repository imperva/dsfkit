#!/bin/bash
# clean_old_deployments.sh: Cleans old deployments on DSF Hub or Agentless Gateway nodes
# Note: This script must not contain an apostrophe, since its contents are wrapped by apostrophes when run
set -e
#set -x
set -u

# Redirect stderr to stdout
exec 2>&1

echo -e "\n-----------------------------------------------------------"
echo "Running clean old deployments bash script at $(date)"

echo "Running as user: $(whoami)"
echo "Running in directory: $(pwd)"

# TODO currently the "clean-old-deployments" supported only from 4.12 version but only in interactive mode,
#  need to adjust this code after non-interactive mode will be supported
#JSONAR_BASEDIR=$(grep "^JSONAR_BASEDIR=" /etc/sysconfig/jsonar | cut -d"=" -f2)

#function run_sonarg_setup() {
#    # This line is in comment since it is not really in full no-interactive mode
#    sudo $JSONAR_BASEDIR/bin/sonarg-setup --no-interactive clean-old-deployments
#}

#run_sonarg_setup


echo "Clean old deployments bash script completed at $(date)"
echo "-------------------------------------------------------------"
