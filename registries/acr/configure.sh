#!/bin/bash

# Install azure cli
source `dirname "${BASH_SOURCE[0]}"`/../../install.sh az

az acr login --name $ACR_USERNAME

IMAGE_REPOSITORY_PREFIX="${ACR_USERNAME}.azurecr.io"
NAMESPACE_INIT_FLAGS="${NAMESPACE_INIT_FLAGS:-} --secret push-credentials"

fats_image_repo() {
  local function_name=$1

  echo -n "${IMAGE_REPOSITORY_PREFIX}/${function_name}:${CLUSTER_NAME}"
}

fats_delete_image() {
  local image=$1

  az acr repository delete --name $ACR_USERNAME --image $image --yes
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
    build.knative.dev/docker-0: https://${ACR_USERNAME}.azurecr.io
type: kubernetes.io/basic-auth
data:
  username: $(echo $ACR_USERNAME)
  password: $(echo $ACR_PASSWORD)
EOF
}
