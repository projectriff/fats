#!/bin/bash

# inspired by https://github.com/LiliC/travis-minikube/blob/minikube-30-kube-1.12/.travis.yml

export CHANGE_MINIKUBE_NONE_USER=true

sudo minikube start --memory=8192 --cpus=4 \
  --kubernetes-version=v1.12.3 \
  --vm-driver=none \
  --bootstrapper=kubeadm \
  --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook" \
  --insecure-registry registry.kube-system.svc.cluster.local

# Fix the kubectl context, as it's often stale.
sudo minikube update-context

# Wait for Kubernetes to be up and ready.
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; \
  until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done

wait_pod_selector_ready component=kube-apiserver kube-system
wait_pod_selector_ready component=kube-scheduler kube-system
wait_pod_selector_ready component=etcd kube-system
