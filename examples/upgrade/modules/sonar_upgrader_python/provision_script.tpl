#!/bin/bash

python -u ${path}/python_upgrader/main.py \
  --target_version "${target_version}" \
  --target_gws_by_id '${target_gws_by_id}' \
  --target_hubs_by_id '${target_hubs_by_id}' \
  --run_preflight_validation "${run_preflight_validation}" \
  --run_postflight_validation "${run_postflight_validation}" \
  --custom_validations_scripts "${custom_validations_scripts}"
