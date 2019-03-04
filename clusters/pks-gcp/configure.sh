#!/bin/bash

# Install pks cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh pks

SYSTEM_INSTALL_FLAGS="${SYSTEM_INSTALL_FLAGS:-}"

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  wait_for_service_ip $name $namespace
}
