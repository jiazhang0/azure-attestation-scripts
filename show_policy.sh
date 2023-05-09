#!/bin/bash

set -e

echo "Showing policy ..."

if [[ $USE_AZ_CLI == "1" ]]; then
  cmd_to_run=$(cat <<EOF
az attestation policy show \
  --name \$AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group \$AZURE_RESOURCE_GROUP \
  --attestation-type \$AZURE_ATTESTATION_TYPE_FOR_AZ_CLI
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
  "https://\$AZURE_MAA_ENDPOINT/policies/\$AZURE_ATTESTATION_TYPE?api-version=\$AZURE_MAA_API_VERSION"
EOF
)

  [[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --verbose"

  cmd_to_run="$cmd_to_run | jq ."

fi

eval $cmd_to_run
