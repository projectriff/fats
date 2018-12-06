#!/bin/bash

IMAGE_REPOSITORY_PREFIX="gcr.io/`gcloud config get-value project`"
NAMESPACE_INIT_FLAGS="${NAMESPACE_INIT_FLAGS:-} --secret push-credentials"

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

# Install gcloud for GCR access
source `dirname "${BASH_SOURCE[0]}"`/../../install.sh gcloud
