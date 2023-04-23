#!/bin/bash
# set -x

sessionid=""
gateway_exists=false
gw_running=false

cookie_file=$(mktemp)

trap "curl -k -s --cookie $cookie_file --request DELETE https://${mx_address}:8083/SecureSphere/api/v1/auth/session; rm -f $cookie_file" EXIT

while true; do
  # Wait 1m before trying again
  sleep 60

  # Step 1: Extract the session cookies
  if ! grep JSESSIONID $cookie_file &>/dev/null; then
    curl -k -s -X POST --cookie-jar $cookie_file "https://${mx_address}:8083/SecureSphere/api/v1/auth/session" \
      --header "Authorization: Basic ${https_auth_header}"
  fi

  # Step 2: Verify gateway group "gateway-group" exists
  if ! $gateway_exists; then
    response=$(curl -k -s -X GET -b $cookie_file "https://${mx_address}:8083/SecureSphere/api/v1/conf/gatewayGroups/${gateway_group_id}")

    if [[ -z "$response" || "$response" == "{}" ]]; then
      echo "Agent Gateway group ${gateway_group_id} doesn't exist yet."
      continue
    fi

    gateway_exists=true
  fi

  # Step 3: Verify gw exists and is running
  if ! $gw_running; then
    response=$(curl -k -s -X GET  -b $cookie_file "https://${mx_address}:8083/SecureSphere/api/v1/conf/gateways/${gateway_id}")

    if [[ -z "$response" || "$response" == "{}" ]]; then
      echo "Agent Gateway ${gateway_id} doesn't exist yet."
      continue
    fi

    running=$(echo "$response" | grep -Po 'running.{2}\K[^,{}]*')

    if [[ "$running" != "true" ]]; then
      echo "Agent Gateway ${gateway_id} is not running yet."
      continue
    fi
    gw_running=true
  fi

  # If all three requirements are met, exit the loop and script
  if $gateway_exists && $gw_running; then
    echo "Agent Gateway ${gateway_id} is up and runnning."
    break
  fi
done

exit 0