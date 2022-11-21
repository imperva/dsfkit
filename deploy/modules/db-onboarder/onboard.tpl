#!/bin/bash
set -e
set -x

client_id="terraform-automation"
reason="Token autogenerated by terraform"
TMPDIR=$(mktemp -u)
mkdir -p ./$TMPDIR
trap "rm -rf ./$TMPDIR" EXIT

function curl_fail_on_error() {
  OUTPUT_FILE=$(mktemp)
  HTTP_CODE=$(curl --silent --output $OUTPUT_FILE --write-out "%%{http_code}" "$@")
  if [[ $HTTP_CODE -lt 200 || $HTTP_CODE -gt 299 ]] ; then
    >&2 cat $OUTPUT_FILE
    return 22
  fi
  cat $OUTPUT_FILE
  rm $OUTPUT_FILE
}

# Generate access token to hub
sudo curl --cacert $JSONAR_LOCALDIR/ssl/ca/ca.cert.pem \
    --cert $JSONAR_LOCALDIR/ssl/client/admin/cert.pem \
    --key $JSONAR_LOCALDIR/ssl/client/admin/key.pem \
    -X POST 'https://localhost:27920/tokens' \
    -H 'Content-type: application/json' \
    -d '{"client_id":"'$client_id'","user":"admin","reason":"'"$reason"'","grants":["usc:access"]}' | jq -r .access_token > ./$TMPDIR/hub_token

hub_token=$(cat ./$TMPDIR/hub_token)

# echo token: $hub_token
if [ -z "$hub_token" ]; then
    echo "Failed to extract token"
    exit 1
fi

# Add cloud account
if ! curl --fail -k 'https://127.0.0.1:8443/dsf/api/v1/cloud-accounts/${account_arn}' --header "Authorization: Bearer $hub_token" &>/dev/null; then
    echo ********Adding new cloud account********
    curl_fail_on_error -k --location --request POST 'https://127.0.0.1:8443/dsf/api/v1/cloud-accounts' \
        --header "Authorization: Bearer $hub_token" \
        --header 'Content-Type: application/json' \
        --data-raw '${cloud_account_data}'
fi

# Add database asset
if ! curl --fail -k 'https://127.0.0.1:8443/dsf/api/v1/data-sources/${db_arn}' --header "Authorization: Bearer $hub_token" &>/dev/null; then
    echo ********Adding new database asset********
    curl_fail_on_error -k --location --request POST 'https://127.0.0.1:8443/dsf/api/v1/data-sources' \
        --header "Authorization: Bearer $hub_token" \
        --header 'Content-Type: application/json' \
        --data-raw '${database_asset_data}'
    echo ********Sleeping 60 seconds before enabling audit logs********
    sleep 60
fi

# Enable audit
echo ********Enabling audit on new asset********
curl_fail_on_error -k --location --request POST 'https://127.0.0.1:8443/dsf/api/v1/data-sources/${db_arn}/operations/enable-audit-collection' \
    --header "Authorization: Bearer $hub_token" \
    --header 'Content-Type: application/json'

# Verify log aggregator is active
max_sleep=600
while true; do
    if [ "$(curl_fail_on_error -k 'https://127.0.0.1:8443/dsf/api/v1/log-aggregators/${db_arn}' --header "Authorization: Bearer $hub_token" | jq -r .data.auditState)" == "YES" ]; then
        echo ********Log aggregator is found********
        break
    fi
    sleep 20
    max_sleep=$(($max_sleep - 20))
    if [ "$max_sleep" -le 0 ]; then
        echo ********Log aggregator is NOT found********
        exit 1
    fi
done
echo DONE
