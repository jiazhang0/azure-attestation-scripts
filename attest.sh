#!/bin/bash

set -e
echo "Attesting $AZURE_ATTESTATION_TYPE ..."

function base64url_encode {
    local base64_encoded=$(echo -n "$*" | base64 -w0 | tr '+/' '-_')
    local base64url_encoded=$(echo -n "$base64_encoded" | sed 's/=*$//')

    echo "$base64url_encoded"
}

uvm=$(cat <<EOF
{
  "Uvm": [ "$(./base64url_encode.py samples/security-context/uvm_reference_info.bin)" ]
}
EOF
)

./gen_vcek_cert_chain.py > vcek_cert_chain.pem

report=$(cat <<EOF
{
  "SnpReport": "$(./base64url_encode.py samples/report.bin)",
  "VcekCertChain": "$(./base64url_encode.py vcek_cert_chain.pem)",
  "Endorsements": "$(base64url_encode $uvm)"
}
EOF
)

attest_req_body=$(cat <<EOF
{
  "report": "$(base64url_encode $report)",
  "runtimeData": {
    "data": "$(./base64url_encode.py samples/report_data)",
    "dataType": "JSON"
  },
  "initTimeData": {
    "data": "",
    "dataType": ""
  },
  "nonce": $(cat /dev/urandom | tr -dc 1-9 | fold -w 20 | head -n1)
}
EOF
)

cmd_to_run=$(cat <<EOF
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer `az account get-access-token \
    --resource https://attest.azure.net \
    --query accessToken --output tsv`" \
  -d "\$attest_req_body" \
  "https://\$AZURE_MAA_ENDPOINT/attest/$AZURE_ATTESTATION_TYPE?api-version=\$AZURE_MAA_API_VERSION"
EOF
)

[[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --verbose"

cmd_to_run="$cmd_to_run | jq ."

eval $cmd_to_run

[[ "$AUTO_CLEANUP" == "1" ]] && rm -f vcek_cert_chain.pem || exit 0
