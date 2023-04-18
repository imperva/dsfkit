#!/bin/bash
set -x

cookie_file=$(mktemp)
trap "rm -f $cookie_file" EXIT

while true; do
  response=$(curl -k -s --cookie-jar $cookie_file -o /dev/null -w "%%{http_code}" \
    --request POST 'https://${mx_address}:8083/SecureSphere/api/v1/auth/session' \
    --header "Authorization: Basic ${https_auth_header}")
  if [ $response -eq 200 ]; then
    curl -k -s --cookie $cookie_file --request DELETE 'https://${mx_address}:8083/SecureSphere/api/v1/auth/session'
    exit 0
  else
    sleep 60
  fi
done