#!/bin/bash

source ./util.sh

curl https://storage.googleapis.com/kubernetes-helm/helm-v2.8.1-linux-amd64.tar.gz \
  | tar xz
chmod +x linux-amd64/helm
sudo mv linux-amd64/helm /usr/local/bin/

kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller \
  --clusterrole cluster-admin \
  --serviceaccount=kube-system:tiller
helm init --service-account=tiller

until kube_ready \
  'pods' \
  'kube-system' \
  'app=helm,name=tiller' \
  '{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  'Ready=True' \
; do sleep 1; done
