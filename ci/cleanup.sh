#!/bin/bash

set -o nounset

source `dirname "${BASH_SOURCE[0]}"`/../.util.sh

# attempt to cleanup riff and the cluster
echo "Uninstall riff system"
helm delete --purge riff
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=riff

helm delete --purge istio
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=istio
kubectl delete namespace istio-system

helm reset
kubectl delete serviceaccount tiller -n kube-system
kubectl delete clusterrolebinding tiller

kubectl delete namespace $NAMESPACE

source `dirname "${BASH_SOURCE[0]}"`/../cleanup.sh
