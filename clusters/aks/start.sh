#!/bin/bash

az aks create --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --service-principal $(echo $AZURE_ENV | base64 --decode | jq -r .appId) \
  --client-secret $(echo $AZURE_ENV | base64 --decode | jq -r .password) \
  --generate-ssh-keys \
  --kubernetes-version 1.10.9 \
  --node-vm-size Standard_DS3_v2

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --admin
