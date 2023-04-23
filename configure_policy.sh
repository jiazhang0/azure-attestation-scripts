#!/bin/bash

set -e

echo "Configuring policy ..."

maa_trust_model=$(az attestation show \
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --query trustModel --output tsv)

if [[ "$maa_trust_model" == "Isolated" ]]; then
  ./sign_jws.py --payload policy \
    --signing-key my_policy_signing_private_key.pem \
    --signing-cert my_policy_signing_cert.pem
elif [[ "$maa_trust_model" == "AAD" ]]; then
  ./sign_jws.py --payload policy
else
  echo "Unsupported MAA trust model $maa_trust_model"
  exit 1
fi

policy_to_configure=policy.jws

if [[ $USE_AZ_CLI == "1" ]]; then
  cmd_to_run=$(cat <<EOF
az attestation policy set
  --name \$AZURE_MAA_CUSTOM_RESOURCE_NAME
  --resource-group \$AZURE_RESOURCE_GROUP
  --attestation-type \$AZURE_ATTESTATION_TYPE_FOR_AZ_CLI
  --new-attestation-policy-file "\$policy_to_configure"
EOF
)

  [[ "$maa_trust_model" == "Isolated" ]] && cmd_to_run="$cmd_to_run --policy-format JWT"
  [[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --debug --verbose"

else
  cmd_to_run=$(cat <<EOF
curl -X PUT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer `az account get-access-token \
    --resource https://attest.azure.net \
    --query accessToken --output tsv`" \
  -d "\$(cat \$policy_to_configure)" \
  "https://\$AZURE_MAA_ENDPOINT/policies/\$AZURE_ATTESTATION_TYPE?api-version=\$AZURE_MAA_API_VERSION"
EOF
)

  [[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --verbose"

  cmd_to_run="$cmd_to_run | jq ."

fi

eval $cmd_to_run
