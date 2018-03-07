#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

curl https://storage.googleapis.com/kubernetes-helm/helm-${1}-linux-amd64.tar.gz | tar xz
chmod +x linux-amd64/helm
sudo mv linux-amd64/helm /usr/local/bin/

kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account=tiller

JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; \
  until kubectl get pods --namespace=kube-system -l app=helm,name=tiller -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done
