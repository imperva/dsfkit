#!/bin/bash

# TODO install/create/activate the virtual environment

pip install -r ${path}/python_upgrader/requirements.txt

python3 -u ${path}/python_upgrader/main.py \
  --target_version "${target_version}" \
  --agentless_gws '${agentless_gws}' \
  --dsf_hubs '${dsf_hubs}' \
  --run_preflight_validations "${run_preflight_validations}" \
  --run_postflight_validations "${run_postflight_validations}" \
  --custom_validations_scripts "${custom_validations_scripts}" \
  --run_upgrade "${run_upgrade}"
