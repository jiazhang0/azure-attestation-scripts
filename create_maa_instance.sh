#!/bin/bash

set -e

cmd_to_run=$(cat <<EOF
az attestation create
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME
  --resource-group $AZURE_RESOURCE_GROUP
  --location $AZURE_RESOURCE_GROUP_LOCATION
EOF
)

[ -f root_policy_signing_cert.pem ] && cmd_to_run="$cmd_to_run --certs-input-path root_policy_signing_cert.pem"
[[ "$DEBUG" == "1" ]] && cmd_to_run="$cmd_to_run --debug --verbose"

eval $cmd_to_run

# Assign RBAC roles to the resource owner so they can set policy
scope=`az attestation show -n $AZURE_MAA_CUSTOM_RESOURCE_NAME -g $AZURE_RESOURCE_GROUP --query id -o tsv`
az role assignment create \
  --role "Attestation Contributor" \
  --assignee `az ad user list --query [0].id -o tsv` \
  --scope $scope
az role assignment create \
  --role "Attestation Reader" \
  --assignee `az ad user list --query [0].id -o tsv` \
  --scope $scope
