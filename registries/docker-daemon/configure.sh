#!/bin/bash

file='/etc/docker/daemon.json'
if test -f ${file} && grep -q registry.kube-system ${file}; then
  echo "insecure registry previously configured"
else
  # Allow for insecure registries
  sudo su -c "echo '{ \"insecure-registries\" : [ \"registry.kube-system.svc.cluster.local\" ] }' > /etc/docker/daemon.json"
  sudo systemctl daemon-reload
  sudo systemctl restart docker
fi

IMAGE_REPOSITORY_PREFIX="registry.kube-system.svc.cluster.local"

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
