#!/bin/bash

# Install eksctl cli
source `dirname "${BASH_SOURCE[0]}"`/../../install.sh eksctl

SYSTEM_INSTALL_FLAGS="${SYSTEM_INSTALL_FLAGS:-}"

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  wait_for_service_hostname $name $namespace .elb.amazonaws.com
}
