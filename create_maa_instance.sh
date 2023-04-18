#!/bin/bash

set -e

cmd_to_run=$(cat <<EOF
az attestation create
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME
  --resource-group $AZURE_RESOURCE_GROUP
  --location $AZURE_RESOURCE_GROUP_LOCATION
EOF
)

[ -f root_policy_signing_cert.pem ] && cmd_to_run="$cmd_to_run --certs-input-path root_policy_signing_cert.pem"

eval $cmd_to_run
