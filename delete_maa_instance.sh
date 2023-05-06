#!/bin/bash

set -e

az attestation delete \
  --yes \
  --name $AZURE_MAA_CUSTOM_RESOURCE_NAME \
  --resource-group $AZURE_RESOURCE_GROUP
