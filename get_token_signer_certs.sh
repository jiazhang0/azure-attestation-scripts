#!/bin/bash

set -e

echo "Getting the token signer certificates ..."

cmd_to_run=$(cat <<EOF
curl -X GET
  https://$AZURE_MAA_ENDPOINT/certs
EOF
)

[[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --debug --verbose"
cmd_to_run="$cmd_to_run | jq ."

eval $cmd_to_run
