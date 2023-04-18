#!/bin/bash

set -e

echo "Deleting policy signing certificate ..."

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
    "https://$AZURE_MAA_ENDPOINT/certificates:remove?api-version=2022-08-01" | \
  jq .
fi

[[ "$AUTO_CLEANUP" == "1" ]] && rm -f my_policy_signing_cert.pem.jws
