#!/bin/bash

# Install minikube cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh docker-desktop

SYSTEM_INSTALL_FLAGS="${SYSTEM_INSTALL_FLAGS:---node-port}"

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  # nothing to do
}
