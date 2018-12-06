#!/bin/bash

# Install minikube cli
source `dirname "${BASH_SOURCE[0]}"`/../../install.sh minikube

SYSTEM_INSTALL_FLAGS="${SYSTEM_INSTALL_FLAGS:---node-port}"

wait_for_ingress_ready() {
  name=$1
  namespace=$2

  # nothing to do
}
