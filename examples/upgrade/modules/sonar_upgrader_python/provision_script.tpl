#!/bin/bash

python3 -u ${path}/python_upgrader/main.py \
  --target_version "${target_version}" \
  --target_agentless_gws '${target_agentless_gws}' \
  --target_hubs '${target_hubs}' \
  --run_preflight_validations "${run_preflight_validations}" \
  --run_postflight_validations "${run_postflight_validations}" \
  --custom_validations_scripts "${custom_validations_scripts}"
