#!/bin/bash

# Install eksctl cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh eksctl

export DUFFLE_RIFF_INSTALL_FLAGS="${DUFFLE_RIFF_INSTALL_FLAGS:-} -s node_port=false"

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  wait_for_service_hostname $name $namespace .elb.amazonaws.com
}
