#!/bin/bash

# Use GCR as a container registry

export USER_ACCOUNT="gcr.io/`gcloud config get-value project`"
export SYSTEM_INSTALL_FLAGS=""

fats_delete_image() {
  image=$1

  gcloud container images delete $image
}

fats_create_push_credentials() {
  namespace="$1"

  echo "Create auth secret"
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: push-credentials
  namespace: $(echo -n "$namespace")
  annotations:
    build.knative.dev/docker-0: https://us.gcr.io
    build.knative.dev/docker-1: https://gcr.io
    build.knative.dev/docker-2: https://eu.gcr.io
    build.knative.dev/docker-3: https://asia.gcr.io
type: kubernetes.io/basic-auth
data:
  username: $(echo -n "_json_key" | openssl base64 -a -A) # Should be X2pzb25fa2V5
  password: $(echo $GCLOUD_CLIENT_SECRET)
EOF
}
