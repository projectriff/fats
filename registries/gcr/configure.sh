#!/bin/bash

# Install gcloud for GCR access
`dirname "${BASH_SOURCE[0]}"`/../../install.sh gcloud

if [ "$machine" == "MinGw" ]; then
  # `gcloud auth configure-docker` doesn't work on Windows for some reason
  echo "${GCLOUD_CLIENT_SECRET}" | base64 --decode | docker login -u _json_key --password-stdin https://gcr.io
else
  gcloud auth configure-docker
fi

IMAGE_REPOSITORY_PREFIX="gcr.io/`gcloud config get-value project`"
NAMESPACE_INIT_FLAGS="${NAMESPACE_INIT_FLAGS:-} --secret push-credentials"

fats_image_repo() {
  local function_name=$1

  echo -n "${IMAGE_REPOSITORY_PREFIX}/${function_name}:${CLUSTER_NAME}"
}

fats_delete_image() {
  local image=$1

  gcloud container images delete $image --force-delete-tags
}

fats_create_push_credentials() {
  local namespace=$1

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
