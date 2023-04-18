#!/bin/bash

set -e

az attestation create \
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --location $AZURE_RESOURCE_GROUP_LOCATION
