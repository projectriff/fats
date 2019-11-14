#!/bin/bash

set -o nounset

source ${FATS_DIR}/.util.sh

echo "Uninstall riff system"

source ${FATS_DIR}/macros/cleanup-user-resources.sh

helm delete --purge riff
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=riff

helm delete --purge istio
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=istio
kubectl delete namespace istio-system

helm delete --purge cert-manager
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=cert-manager

source ${FATS_DIR}/macros/helm-reset.sh

kubectl delete namespace ${NAMESPACE}
