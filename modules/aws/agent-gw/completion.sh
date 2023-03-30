#!/bin/bash

set -x

# Set initial values to null
sessionid=""
gateway_exists=false
gw_running=false

while true; do
  # Wait 5 seconds before trying again
  sleep 5

  # Step 1: Extract sessionid & SSOSESSIONID cookies
  if [[ -z "$sessionid" ]]; then
    cookies=$(curl -k -s -X POST "https://${mx_address}:8083/SecureSphere/api/v1/auth/session" \
      --header "Authorization: Basic ${http_auth_header}")

    sessionid=$(echo "$cookies" | jq -r .\"session-id\")

    if [[ -z "$sessionid" ]]; then
      echo "Failed to extract cookies."
      continue
    fi
  fi

  # Step 2: Verify gateway group "gateway-group-uuid" exists
  if ! $gateway_exists; then
    response=$(curl -k -s -X GET "https://${mx_address}:8083/SecureSphere/api/v1/conf/gatewayGroups/${gateway_group_id}" \
      --header "Cookie: $sessionid")

    if [[ -z "$response" || "$response" == "{}" ]]; then
      echo "Failed to verify gateway group exists."
      continue
    fi

    gateway_exists=true
  fi

  # Step 3: Verify gw exists and is running
  if ! $gw_running; then
    response=$(curl -k -s -X GET "https://${mx_address}:8083/SecureSphere/api/v1/conf/gateways/${gateway_id}" \
      --header "Cookie: $sessionid")

    if [[ -z "$response" || "$response" == "{}" ]]; then
      echo "Failed to verify gateway exists."
      continue
    fi

    running=$(echo "$response" | grep -Po ""running":\K[^,]*")

    if [[ "$running" != "true" ]]; then
      echo "Gateway is not running."
      continue
    fi

    gw_running=true
    exit 0
  fi

  # If all three requirements are met, exit the loop and script
  if $gateway_exists && $gw_running; then
    echo "All requirements met. Exiting script."
    break
  fi
done
