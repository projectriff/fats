#!/bin/bash

# delete job resources

az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --yes
