#!/bin/bash
set -x
set -e

cookie_file=$(mktemp)
response_file=$(mktemp)

http_code=$(curl -k -s --cookie-jar $cookie_file -o $response_file -w "%%{http_code}" \
  --request POST 'https://${mx_address}:8083/SecureSphere/api/v1/auth/session' \
  --header "Authorization: Basic ${https_auth_header}")
if [ $http_code -ne 200 ]; then
  echo "Failed to authenticate. http_code: $http_code."
  exit 1
fi

trap "echo Running trap:; curl -k -s --cookie $cookie_file --request DELETE 'https://${mx_address}:8083/SecureSphere/api/v1/auth/session'; rm -f $cookie_file" EXIT

%{ for config_value in configuration_elements }
echo "Setting ${config_value.name}:"
while true; do
  http_code=$(curl -k -s --cookie $cookie_file -o $response_file -w "%%{http_code}" \
    --request ${config_value.method} 'https://${mx_address}:8083/${config_value.url_path}' \
    --header 'Content-Type: application/json' \
    --data-raw '${config_value.payload}')
  if [ "$http_code" -eq 200 ]; then
    echo "Done with ${config_value.name}:"
    break
  fi
  if [ "$http_code" -eq 406 ]; then
    if grep IMP-10005 $response_file; then
      # resource already exists
      echo "Done with ${config_value.name}:"
      break
    fi
  fi
  echo "sleep 1m"
  sleep 1m
done
%{ endfor ~}

# {"errors":[{"description":"System is busy. Please try again later.","error-code":"IMP-10001"}]}
# {"errors":[{"description":"Server Group not found","error-code":"IMP-10008"}]}
# {"errors":[{"description":"System is busy. Please try again later.","error-code":"IMP-10001"}]}
# {"errors":[{"description":"The \"db-service-type\" entered is illegal","error-code":"IMP-10016"}]}