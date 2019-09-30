#!/bin/bash

# Install gcloud cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh gcloud

export K8S_SERVICE_TYPE=LoadBalancer

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  wait_for_service_ip $name $namespace
}

registry_started() {
  local registry=$1

  # nothing to do
}
