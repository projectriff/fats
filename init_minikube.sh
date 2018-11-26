#!/bin/bash

export USER_ACCOUNT="registry.kube-system.svc.cluster.local/u"
export SYSTEM_INSTALL_FLAGS="${SYSTEM_INSTALL_FLAGS:---node-port}"
export NAMESPACE_INIT_FLAGS="${NAMESPACE_INIT_FLAGS:---secret push-credentials}"

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

  echo "Create auth secret"
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: push-credentials
  namespace: $(echo -n "$namespace")
type: kubernetes.io/basic-auth
EOF
}
