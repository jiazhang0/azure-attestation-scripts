#!/bin/bash

set -e

echo "Deleting the MAA instance $AZURE_MAA_CUSTOM_RESOURCE_NAME ..."

az attestation delete \
  --yes \
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group $AZURE_RESOURCE_GROUP
