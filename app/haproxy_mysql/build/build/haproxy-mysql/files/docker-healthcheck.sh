#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


CHECK_HOST="http://localhost:80"
CHECK_PATH="/"
CHECK_STRING="front"

# Build curl options variable
CURL_OPTS="--user ${HAPROXY_STATS_AUTH_USER:-haproxy}:${HAPROXY_STATS_AUTH_PASSWORD:-haproxy}"

# Run curl with appropriate options
curl ${CURL_OPTS}  -m 2 -k ${CHECK_HOST}/${CHECK_PATH} 2>/dev/null | grep -q "${CHECK_STRING}"
#exit $?