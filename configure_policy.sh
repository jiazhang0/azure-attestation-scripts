#!/bin/bash

set -e

echo "Configuring policy ..."

./sign_jws.py --payload policy \
  --signing-key my_policy_signing_private_key.pem \
  --signing-cert my_policy_signing_cert.pem

policy_to_configure=$(cat policy.jws)

if [[ $USE_AZ_CLI == "1" ]]; then
  az attestation policy set \
    --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --attestation-type $AZURE_ATTESTATION_TYPE_FOR_AZ_CLI \
    --policy-format JWT \
    --new-attestation-policy-file policy.jws
else
  curl -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer `az account get-access-token \
      --resource https://attest.azure.net \
      --query accessToken --output tsv`" \
    -d "$policy_to_configure" \
    "https://$AZURE_MAA_ENDPOINT/policies/$AZURE_ATTESTATION_TYPE?api-version=2022-08-01" | \
  jq .
fi
