#!/bin/bash

set -e

echo "Adding new policy signing certificate ..."

./sign_jws.py --payload my_policy_signing_cert.pem \
  --signing-key root_policy_signing_private_key.pem \
  --signing-cert root_policy_signing_cert.pem

policy_signing_cert_to_add=$(cat my_policy_signing_cert.pem.jws)

if [[ $USE_AZ_CLI == "1" ]]; then
  az attestation signer add \
    --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --signer $policy_signing_cert_to_add
else
  curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer `az account get-access-token \
      --resource https://attest.azure.net \
      --query accessToken --output tsv`" \
    -d "\"$policy_signing_cert_to_add\"" \
    "https://$AZURE_MAA_ENDPOINT/certificates:add?api-version=2022-08-01" | \
  jq .
fi
