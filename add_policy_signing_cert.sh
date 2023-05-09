#!/bin/bash

set -e

echo "Adding new policy signing certificate ..."

maa_trust_model=$(az attestation show \
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --query trustModel --output tsv)

if [[ "$maa_trust_model" == "AAD" ]]; then
  echo "AAD trust model doesn't support to add policy signing cert"
  exit 0
fi

./sign_jws.py --payload my_policy_signing_cert.pem \
  --signing-key root_policy_signing_private_key.pem \
  --signing-cert root_policy_signing_cert.pem

policy_signing_cert_to_add=$(cat my_policy_signing_cert.pem.jws)

if [[ $USE_AZ_CLI == "1" ]]; then
  cmd_to_run=$(cat <<EOF
az attestation signer add \
  --name \$AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group \$AZURE_RESOURCE_GROUP \
  --signer \$policy_signing_cert_to_add
EOF
)

  [[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --debug --verbose"

else
  cmd_to_run=$(cat <<EOF
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer `az account get-access-token \
    --resource https://attest.azure.net \
    --query accessToken --output tsv`" \
  -d "\"\$policy_signing_cert_to_add\"" \
  "https://\$AZURE_MAA_ENDPOINT/certificates:add?api-version=\$AZURE_MAA_API_VERSION"
EOF
)

  [[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --verbose"

  cmd_to_run="$cmd_to_run | jq ."

fi

eval $cmd_to_run
