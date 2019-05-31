#!/bin/bash

# Install minikube cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh minikube
minikube config set embed-certs true

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  # nothing to do
}
