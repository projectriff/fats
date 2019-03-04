#!/bin/bash

# Install gcloud cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh gcloud

SYSTEM_INSTALL_FLAGS="${SYSTEM_INSTALL_FLAGS:-}"

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  wait_for_service_ip $name $namespace
}
