#!/bin/bash

export USER_ACCOUNT="registry.kube-system.svc.cluster.local/u"
export SYSTEM_INSTALL_FLAGS="${SYSTEM_INSTALL_FLAGS:---node-port}"
export NAMESPACE_INIT_FLAGS="${NAMESPACE_INIT_FLAGS:---no-secret}"

wait_for_ingress_ready() {
  name=$1
  namespace=$2

  # nothing to do
}

fats_delete_image() {
  image=$1

  # nothing to do
}

fats_create_push_credentials() {
  namespace=$1

  # nothing to do
}
