#!/bin/bash

# Install gcloud cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh gcloud

export DUFFLE_RIFF_INSTALL_FLAGS="${DUFFLE_RIFF_INSTALL_FLAGS:-} -s node_port=false"

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  wait_for_service_ip $name $namespace
}
