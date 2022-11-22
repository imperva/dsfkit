# Compute Signature
# dateValue=`date -R`
# contentType="application/x-compressed-tar"
# s3key="deployments"

# access="$AWS_ACCESS_KEY_ID"
# secret="$AWS_SECRET_ACCESS_KEY"
# contentType="application/x-compressed-tar"
# resource="/${statistics_bucket_name}/${s3key}/${file_name}"

# string="PUT\n\n${contentType}\n${dateValue}\n${resource}"
# signature=`echo -en ${string} | openssl sha1 -hmac "${secret}" -binary | base64` 

# curl -X PUT -T "${file_name}" \
#   -H "Host: ${statistics_bucket_name}.s3.amazonaws.com" \
#   -H "Date: ${dateValue}" \
#   -H "Content-Type: ${contentType}" \
#   -H "Authorization: AWS ${access}:${signature}" \
#   https://${statistics_bucket_name}.s3.amazonaws.com/${s3key}/${file_name}