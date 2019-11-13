#!/bin/bash

# Install kind cli
`dirname "${BASH_SOURCE[0]}"`/../../install.sh kind

export K8S_SERVICE_TYPE=NodePort
CLUSTER_NAME=${CLUSTER_NAME-fats}

wait_for_ingress_ready() {
  local name=$1
  local namespace=$2

  # nothing to do
}

post_registry_start() {
  local registry=$1

  if [ $registry = "docker-daemon" ] ; then
    local registry_ip=$(docker inspect --format "{{.NetworkSettings.IPAddress }}" registry)

    # patch /etc/containerd/config.toml
    docker cp ${CLUSTER_NAME}-control-plane:/etc/containerd/config.toml containerd-config.toml
    while IFS= read -r line
    do
      echo "$line" >> containerd-config-patched.toml
      if [[ $line = *'[plugins.cri.registry.mirrors]'* ]] ; then
        spaces=$(echo "$line" | cut -d '[' -s -f 1)
        echo -n "$spaces" >> containerd-config-patched.toml
        echo '  [plugins.cri.registry.mirrors."registry.kube-system.svc.cluster.local:5000"]' >> containerd-config-patched.toml
        echo -n "$spaces" >> containerd-config-patched.toml
        echo "    endpoint = [\"http://${registry_ip}:5000\"]" >> containerd-config-patched.toml
      fi
    done < "containerd-config.toml"
    docker cp containerd-config-patched.toml ${CLUSTER_NAME}-control-plane:/etc/containerd/config.toml

    # add to /etc/hosts
    docker exec ${CLUSTER_NAME}-control-plane bash -c "echo \"${registry_ip} registry.kube-system.svc.cluster.local\" >> /etc/hosts"

    # restart containerd
    docker exec ${CLUSTER_NAME}-control-plane bash -c 'systemctl daemon-reload'
    docker exec ${CLUSTER_NAME}-control-plane bash -c 'systemctl restart containerd'
    docker exec ${CLUSTER_NAME}-control-plane bash -c 'systemctl restart kubelet'
    # TODO figure out what to watch instead of sleep
    sleep 60
  fi
}
