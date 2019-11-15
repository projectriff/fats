#!/bin/bash

# Allow for insecure registries as long as docker daemon is actually running
if ! grep -q docker /proc/1/cgroup; then
  daemonConfig='/etc/docker/daemon.json'
  if test -f ${daemonConfig} && grep -q registry.kube-system.svc.cluster.local ${daemonConfig}; then
    echo "insecure registry previously configured"
  else
    if ! test -f ${daemonConfig} || test -s ${daemonConfig}; then
      sudo mkdir -p /etc/docker
      echo '{}' | sudo tee ${daemonConfig} > /dev/null
    fi
    jq -s '.[0] * .[1]' <( cat ${daemonConfig}) <(echo '{ "insecure-registries": [ "registry.kube-system.svc.cluster.local:5000" ] }') | sudo tee ${daemonConfig} > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart docker
  fi
fi

IMAGE_REPOSITORY_PREFIX="registry.kube-system.svc.cluster.local:5000"

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
