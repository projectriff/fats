#!/bin/bash

SYSTEM_INSTALL_FLAGS="${SYSTEM_INSTALL_FLAGS:-}"

wait_for_ingress_ready() {
  name=$1
  namespace=$2

  wait_for_service_ip $name $namespace
}

# Install gcloud cli
source `dirname "${BASH_SOURCE[0]}"`/../../install.sh gcloud
