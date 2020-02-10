#!/bin/bash

cat <<EOF > ${CLUSTER_NAME}.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
EOF

if [ "$REGISTRY" = "docker-daemon" ] ; then
  # patch cluster config for registry location
  cat <<EOF >> ${CLUSTER_NAME}.yaml
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.kube-system.svc.cluster.local:5000"]
    endpoint = ["http://$(docker inspect --format "{{.NetworkSettings.IPAddress }}" registry):5000"]
EOF
fi

kind create cluster --name ${CLUSTER_NAME} \
  --config ${CLUSTER_NAME}.yaml \
  --image kindest/node:v1.15.7 \
  --wait 5m

if [ "$REGISTRY" = "docker-daemon" ] ; then
  docker exec ${CLUSTER_NAME}-control-plane bash -c "echo \"$(docker inspect --format "{{.NetworkSettings.IPAddress }}" registry) registry.kube-system.svc.cluster.local\" >> /etc/hosts"
fi

# move kubeconfig to expected location
mkdir -p ~/.kube
if grep -q docker /proc/1/cgroup; then
  # running in a container
  cp <(kind get kubeconfig --name ${CLUSTER_NAME} --internal) ~/.kube/config
else
  cp <(kind get kubeconfig --name ${CLUSTER_NAME}) ~/.kube/config
fi
