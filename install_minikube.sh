#!/bin/bash

source ./util.sh

# inspired by https://github.com/LiliC/travis-minikube/blob/minikube-26-kube-1.10/.travis.yml

export CHANGE_MINIKUBE_NONE_USER=true

# install minikube if needed
if hash minikube 2>/dev/null; then
  echo "Skipping minikube install"
else
  echo "Installing minikube"
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
  chmod +x minikube && \
  sudo mv minikube /usr/local/bin/
fi

# Make root mounted as rshared to fix kube-dns issues.
sudo mount --make-rshared /

sudo minikube start --memory=8192 --cpus=4 \
  --vm-driver=none \
  --bootstrapper=kubeadm \
  --kubernetes-version=v1.12.0 \
  --extra-config=apiserver.admission-control="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"

# Fix the kubectl context, as it's often stale.
minikube update-context

# Wait for Kubernetes to be up and ready.
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; \
  until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done
