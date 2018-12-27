#!/bin/bash

# Install azure cli
source `dirname "${BASH_SOURCE[0]}"`/../../install.sh az

SYSTEM_INSTALL_FLAGS="${SYSTEM_INSTALL_FLAGS:-}"

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  wait_for_service_ip $name $namespace
}

# custom azure config

export LOCATION=eastus
export RESOURCE_GROUP=`echo $CLUSTER_NAME | cut -d '-' -f1`

az group create --name $RESOURCE_GROUP --location $LOCATION

az provider register -n Microsoft.Compute
az provider register -n Microsoft.Network
