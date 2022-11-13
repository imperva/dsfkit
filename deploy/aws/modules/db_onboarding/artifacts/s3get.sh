#!/bin/bash

function s3get {
	#helper functions
	function fail {	echo "$1" > /dev/stderr; exit 1; }
	#dependency check
	if ! hash openssl 2>/dev/null; then fail "openssl not installed"; fi
	if ! hash curl 2>/dev/null; then fail "curl not installed"; fi
	#params
	path="${1}"
	bucket=$(cut -d '/' -f 1 <<< "$path")
	key=$(cut -d '/' -f 2- <<< "$path")
	#load creds
	access="$AWS_ACCESS_KEY_ID"
	secret="$AWS_SECRET_ACCESS_KEY"
	#validate
	if [[ "$bucket" = "" ]]; then fail "missing bucket (arg 1)"; fi;
	if [[ "$key" = ""    ]]; then fail "missing key (arg 1)"; fi;
	if [[ "$access" = "" ]]; then fail "missing AWS_ACCESS_KEY (env var)"; fi;
	if [[ "$secret" = "" ]]; then fail "missing AWS_SECRET_KEY (env var)"; fi;
	#compute signature
	contentType="text/html; charset=UTF-8" 
	date="`date -u +'%a, %d %b %Y %H:%M:%S GMT'`"
	resource="/${bucket}/${key}"
	string="GET\n\n${contentType}\n\nx-amz-date:${date}\n${resource}"
	signature=`echo -en $string | openssl sha1 -hmac "${secret}" -binary | base64` 
	#get!
	curl -H "x-amz-date: ${date}" \
		-H "Content-Type: ${contentType}" \
		-H "Authorization: AWS ${access}:${signature}" \
		"https://s3.amazonaws.com${resource}"
}

#example usage
#s3get bucket/path/to/file > /tmp/file