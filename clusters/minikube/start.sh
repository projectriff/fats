#!/bin/bash

if [ "$machine" == "MinGw" ]; then
  vm_driver=hyperv
else
  vm_driver=none

  export MINIKUBE_HOME=$HOME
  export CHANGE_MINIKUBE_NONE_USER=true
  export KUBECONFIG=$HOME/.kube/config

  mkdir -p $HOME/.kube $HOME/.minikube
  touch $KUBECONFIG
fi

sudo -E minikube start --memory=8192 --cpus=4 \
  --kubernetes-version=v1.12.3 \
  --vm-driver=${vm_driver} \
  --bootstrapper=kubeadm \
  --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook" \
  --insecure-registry registry.kube-system.svc.cluster.local
