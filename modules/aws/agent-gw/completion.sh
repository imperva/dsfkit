#!/bin/bash
# set -x

# Set initial values to null
sessionid=""
gateway_exists=false
gw_running=false

cookie_file=$(mktemp)
trap "rm -f $cookie_file" EXIT

while true; do
  # Wait 1m before trying again
  sleep 60

  # Step 1: Extract sessionid & SSOSESSIONID cookies
  if ! grep JSESSIONID $cookie_file &>/dev/null; then
    curl -k -s -X POST -c $cookie_file "https://${mx_address}:8083/SecureSphere/api/v1/auth/session" \
      --header "Authorization: Basic ${http_auth_header}"
  fi

  # Step 2: Verify gateway group "gateway-group-uuid" exists
  if ! $gateway_exists; then
    response=$(curl -k -s -X GET -b $cookie_file "https://${mx_address}:8083/SecureSphere/api/v1/conf/gatewayGroups/${gateway_group_id}")

    if [[ -z "$response" || "$response" == "{}" ]]; then
      echo "Failed to verify gateway group exists."
      continue
    fi

    gateway_exists=true
  fi

  # Step 3: Verify gw exists and is running
  if ! $gw_running; then
    response=$(curl -k -s -X GET  -b $cookie_file "https://${mx_address}:8083/SecureSphere/api/v1/conf/gateways/${gateway_id}")

    if [[ -z "$response" || "$response" == "{}" ]]; then
      echo "Failed to verify gateway exists."
      continue
    fi

    running=$(echo "$response" | grep -Po 'running.{2}\\\\\\K[^,{}]*')

    if [[ "$running" != "true" ]]; then
      echo "Gateway is not running."
      continue
    fi

    gw_running=true
  fi

  # If all three requirements are met, exit the loop and script
  if $gateway_exists && $gw_running; then
    echo "All requirements met. Done."
    break
  fi
done

exit 0