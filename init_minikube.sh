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

  # TODO riff requires a secret be provided to `riff namespace init`, but we don't actually need it for a local registry
  echo "Create auth secret"
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: push-credentials
  namespace: $(echo -n "$namespace")
  annotations:
    build.knative.dev/docker-0: https://index.docker.io/v1/
type: kubernetes.io/basic-auth
data:
  username: $(echo -n "$DOCKER_USERNAME" | openssl base64 -a -A)
  password: $(echo -n "$DOCKER_PASSWORD" | openssl base64 -a -A)
EOF
}
