#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh

# inspired by https://github.com/LiliC/travis-minikube/blob/minikube-26-kube-1.10/.travis.yml

export CHANGE_MINIKUBE_NONE_USER=true

VERSION='v0.30.0'
# install minikube if needed
if hash minikube 2>/dev/null; then
  echo "Skipping minikube install"
else
  echo "Installing minikube"
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/$VERSION/minikube-linux-amd64 && \
    chmod +x minikube && sudo mv minikube /usr/local/bin/
fi

# Make root mounted as rshared to fix kube-dns issues.
sudo mount --make-rshared /

sudo minikube start --memory=8192 --cpus=4 \
  --kubernetes-version=v1.12.2 \
  --vm-driver=none \
  --bootstrapper=kubeadm \
  --extra-config=apiserver.enable-admission-plugins="NamespaceExists,NamespaceLifecycle,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"

# Point to minikube docker daemon
eval $(sudo minikube docker-env)

# Fix the kubectl context, as it's often stale.
sudo minikube update-context

# Wait for Kubernetes to be up and ready.
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; \
  until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done
