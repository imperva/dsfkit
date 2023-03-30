#!/bin/bash

set -x

while true; do
  response=$(curl -k -s -o /dev/null -w "%%{http_code}" \
    --request POST 'https://${mx_address}:8083/SecureSphere/api/v1/auth/session' \
    --header "Authorization: Basic ${http_auth_header}")
  if [ $response -eq 200 ]; then
    exit 0
  else
    sleep 30
  fi
done