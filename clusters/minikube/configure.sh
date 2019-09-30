#!/bin/bash

# Install minikube cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh minikube
minikube config set embed-certs true

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME

export K8S_SERVICE_TYPE=NodePort

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  # nothing to do
}

registry_started() {
  local registry=$1

  # nothing to do
}
