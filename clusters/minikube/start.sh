#!/bin/bash

if [ "$machine" == "MinGw" ]; then
  vm_driver=hyperv
else
  export CHANGE_MINIKUBE_NONE_USER=true

  # Make root mounted as rshared to fix kube-dns issues.
  # sudo mount --make-rshared /

  vm_driver=none
fi

sudo minikube start --memory=8192 --cpus=4 \
  --kubernetes-version=v1.12.3 \
  --vm-driver=${vm_driver} \
  --bootstrapper=kubeadm \
  --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook" \
  --insecure-registry registry.kube-system.svc.cluster.local

# Fix permissions issue in AzurePipelines
sudo chmod --recursive 777 $HOME/.minikube
sudo chmod --recursive 777 $HOME/.kube
