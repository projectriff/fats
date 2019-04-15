#!/bin/bash

IMAGE_REPOSITORY_HOST="registry.riff.svc.cluster.local"
IMAGE_REPOSITORY_PREFIX="$IMAGE_REPOSITORY_HOST:5000/u"
NAMESPACE_INIT_FLAGS="${NAMESPACE_INIT_FLAGS:-} --no-secret"

fats_image_repo() {
  local function_name=$1

  echo -n "${IMAGE_REPOSITORY_PREFIX}/${function_name}:${CLUSTER_NAME}"
}

fats_delete_image() {
  local image=$1

  # nothing to do
}

fats_create_push_credentials() {
  local namespace=$1

  # nothing to do
}
