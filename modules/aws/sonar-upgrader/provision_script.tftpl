#!/bin/bash

# Install, create and activate the virtual environment
python3 -m ensurepip --upgrade
pip3 install --user virtualenv
python3 -m virtualenv venv
source venv/bin/activate

pip3 install -r ${path}/python_upgrader/requirements.txt

PYTHONPATH=${path}/python_upgrader python3 -u -m upgrade.main \
  --target_version "${target_version}" \
  --agentless_gws '${agentless_gws}' \
  --dsf_hubs '${dsf_hubs}' \
  --connection_timeout "${connection_timeout}" \
  --test_connection "${test_connection}" \
  --run_preflight_validations "${run_preflight_validations}" \
  --run_upgrade "${run_upgrade}" \
  --run_postflight_validations "${run_postflight_validations}" \
  --stop_on_failure "${stop_on_failure}" \
  --tarball_location '${tarball_location}'
