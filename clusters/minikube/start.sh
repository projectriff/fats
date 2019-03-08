#!/bin/bash

# inspired by https://github.com/LiliC/travis-minikube/blob/minikube-30-kube-1.12/.travis.yml

export CHANGE_MINIKUBE_NONE_USER=true

sudo minikube start --memory=8192 --cpus=4 \
  --kubernetes-version=v1.12.3 \
  --vm-driver=none \
  --bootstrapper=kubeadm \
  --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook" \
  --insecure-registry registry.kube-system.svc.cluster.local
