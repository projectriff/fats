#!/bin/bash

daemonConfig='/etc/docker/daemon.json'
if test -f ${daemonConfig} && grep -q registry.kube-system ${daemonConfig}; then
  echo "insecure registry previously configured"
else
  # Allow for insecure registries
  sudo mkdir -p /etc/docker
  echo '{ "insecure-registries": [ "registry.kube-system.svc.cluster.local" ] }' | sudo tee ${daemonConfig} > /dev/null
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

  # TODO remove this
  echo "fake" | riff credentials apply fake --registry http://example.com --registry-user fake --namespace "${namespace}"
}
