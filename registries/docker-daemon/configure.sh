#!/bin/bash

# Allow for insecure registries
docker-daemon-file="/etc/docker/daemon.json"
if test -f ${docker-daemon-file} && grep -q registry.kube-system ${docker-daemon-file}; then
  # do nothing
else
  sudo su -c "echo '{ \"insecure-registries\" : [ \"registry.kube-system.svc.cluster.local\" ] }' > /etc/docker/daemon.json"
  sudo systemctl daemon-reload
  sudo systemctl restart docker
fi

IMAGE_REPOSITORY_PREFIX="registry.kube-system.svc.cluster.local"
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