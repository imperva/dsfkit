#!/bin/bash
# get_python_location.sh
# Note: This script must not contain an apostrophe, since its contents are wrapped by apostrophes when run
set -e
#set -x
set -u

# Redirect stderr to stdout
exec 2>&1

echo -e "\n-----------------------------------------------------------------------"
echo "Running get python location bash script at $(date)"

echo "Running as user: $(whoami)"
echo "Running in directory: $(pwd)"

JSONAR_BASEDIR=$(grep "^JSONAR_BASEDIR=" /etc/sysconfig/jsonar | cut -d"=" -f2)
PYTHON_LOCATION="$JSONAR_BASEDIR/bin/python3"
# The string "Python location:" is part of the protocol, if you change it, change its usage
echo "Python location: $PYTHON_LOCATION"
echo "-----------------------------------------------------------------------"