#!/bin/bash

IMAGE_REPOSITORY_PREFIX="registry.kube-system.svc.cluster.local/u"
NAMESPACE_INIT_FLAGS="${NAMESPACE_INIT_FLAGS:-} --no-secret"

fats_delete_image() {
  image=$1

  # nothing to do
}

fats_create_push_credentials() {
  namespace=$1

  # nothing to do
}

# Allow for insecure registries
sudo su -c "echo '{ \"insecure-registries\" : [ \"registry.kube-system.svc.cluster.local\" ] }' > /etc/docker/daemon.json"
sudo systemctl daemon-reload
sudo systemctl restart docker
