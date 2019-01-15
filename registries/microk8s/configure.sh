#!/bin/bash

IMAGE_REPOSITORY_PREFIX="localhost:32000"
NAMESPACE_INIT_FLAGS="${NAMESPACE_INIT_FLAGS:-} --no-secret"

fats_image_repo() {
  local function_name=$1

  echo -n "${IMAGE_REPOSITORY_PREFIX}/${function_name}:${CLUSTER_NAME}"
}

fats_delete_image() {
  image=$1

  # nothing to do
}

fats_create_push_credentials() {
  namespace=$1

  # nothing to do
}
