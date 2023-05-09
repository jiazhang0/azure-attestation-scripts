#!/bin/bash

set -e

echo "Listing policy signing certificates ..."

if [[ $USE_AZ_CLI == "1" ]]; then
  cmd_to_run=$(cat <<EOF
az attestation signer list \
  --name \$AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group \$AZURE_RESOURCE_GROUP
EOF
)

  [[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --debug --verbose"

else
  cmd_to_run=$(cat <<EOF
curl -s -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer `az account get-access-token \
    --resource https://attest.azure.net \
    --query accessToken --output tsv`" \
  "https://\$AZURE_MAA_ENDPOINT/certificates?api-version=\$AZURE_MAA_API_VERSION"
EOF
)

  [[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --verbose"

  cmd_to_run="$cmd_to_run | jq ."

fi

eval $cmd_to_run
