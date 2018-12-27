#!/bin/bash

az aks create --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --generate-ssh-keys \
  --kubernetes-version 1.11.5 \
  --node-vm-size Standard_DS3_v2

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --admin
