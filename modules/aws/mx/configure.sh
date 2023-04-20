#!/bin/bash
set -x
set -e

cookie_file=$(mktemp)
trap "curl -k -s --cookie $cookie_file --request DELETE 'https://${mx_address}:8083/SecureSphere/api/v1/auth/session'; rm -f $cookie_file" EXIT

response=$(curl -k -s --cookie-jar $cookie_file -o /dev/null -w "%%{http_code}" \
  --request POST 'https://${mx_address}:8083/SecureSphere/api/v1/auth/session' \
  --header "Authorization: Basic ${https_auth_header}")
if [ $response -eq 200 ]; then
  %{ for config_value in configuration_elements }
  echo "Setting ${config_value.name}:"
  while [ $(curl -k -s --cookie $cookie_file -o /dev/null -w "%%{http_code}" \
      --request ${config_value.method} 'https://${mx_address}:8083/${config_value.url_path}' \
      --header 'Content-Type: application/json' \
      --data-raw '${config_value.payload}') -eq 503 ]; do
    sleep 1m;
  done
  %{ endfor ~}
fi

exit 1