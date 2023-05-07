#!/bin/bash

set -e

echo "Getting the MAA metadata configuration ..."

cmd_to_run=$(cat <<EOF
curl -X GET
  https://$AZURE_MAA_ENDPOINT/.well-known/openid-configuration
EOF
)

[[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --debug --verbose"
cmd_to_run="$cmd_to_run | jq ."

eval $cmd_to_run
