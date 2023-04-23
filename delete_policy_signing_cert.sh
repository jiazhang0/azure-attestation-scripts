#!/bin/bash

set -e

echo "Deleting policy signing certificate ..."

maa_trust_model=$(az attestation show \
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --query trustModel --output tsv)

if [[ "$maa_trust_model" == "AAD" ]]; then
  echo "AAD trust model doesn't support to delete policy signing cert"
  exit 0
fi

policy_signing_cert_to_delete=my_policy_signing_cert.pem.jws

if [[ $USE_AZ_CLI == "1" ]]; then
  az attestation signer remove \
    --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --signer-file $policy_signing_cert_to_delete
else
  requestBody=`cat $policy_signing_cert_to_delete`

  curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer `az account get-access-token \
      --resource https://attest.azure.net \
      --query accessToken --output tsv`" \
    -d "\"$requestBody\"" \
    "https://$AZURE_MAA_ENDPOINT/certificates:remove?api-version=$AZURE_MAA_API_VERSION" | \
  jq .
fi

[[ "$AUTO_CLEANUP" == "1" ]] && rm -f my_policy_signing_cert.pem.jws
