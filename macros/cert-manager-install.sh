#!/bin/bash

kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.10.1/cert-manager.yaml

sleep 10

wait_pod_selector_ready app.kubernetes.io/name=cert-manager cert-manager
wait_pod_selector_ready app.kubernetes.io/name=cainjector cert-manager
wait_pod_selector_ready app.kubernetes.io/name=webhook cert-manager
