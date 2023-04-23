#!/bin/bash

set -e

echo "Resetting policy ..."

maa_trust_model=$(az attestation show \
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --query trustModel --output tsv)

policy_to_reset="policy_to_reset"

if [[ "$maa_trust_model" == "Isolated" ]]; then
  echo -n"" > $policy_to_reset

  ./sign_jws.py --payload $policy_to_reset \
    --signing-key root_policy_signing_private_key.pem \
    --signing-cert root_policy_signing_cert.pem

  payload=$(cat ${policy_to_reset}.jws)
  rm -f $policy_to_reset
elif [[ "$maa_trust_model" == "AAD" ]]; then
  payload="eyJhbGciOiJub25lIn0.."
else
  echo "Unsupported MAA trust model $maa_trust_model"
  exit 1
fi

if [[ $USE_AZ_CLI == "1" ]]; then
  az attestation policy reset \
    --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --attestation-type $AZURE_ATTESTATION_TYPE_FOR_AZ_CLI \
    --policy-jws "$payload"
else
  curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer `az account get-access-token \
      --resource https://attest.azure.net \
      --query accessToken --output tsv`" \
    -d "$payload" \
    "https://$AZURE_MAA_ENDPOINT/policies/$AZURE_ATTESTATION_TYPE:reset?api-version=$AZURE_MAA_API_VERSION" | \
  jq .
fi

[[ "$AUTO_CLEANUP" == "1" ]] && rm -f policy_to_reset.jws policy.jws
