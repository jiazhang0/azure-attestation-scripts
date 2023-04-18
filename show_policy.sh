#!/bin/bash

set -e

echo "Showing policy ..."

if [[ $USE_AZ_CLI == "1" ]]; then
  az attestation policy show \
    --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --attestation-type $AZURE_ATTESTATION_TYPE_FOR_AZ_CLI
else
  curl -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer `az account get-access-token \
      --resource https://attest.azure.net \
      --query accessToken --output tsv`" \
    "https://$AZURE_MAA_ENDPOINT/policies/$AZURE_ATTESTATION_TYPE?api-version=2022-08-01" | \
  jq .
fi
