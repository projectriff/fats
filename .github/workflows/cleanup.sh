#!/bin/bash

set -o nounset

fats_dir=`dirname "${BASH_SOURCE[0]}"`/../..

source ${fats_dir}/.util.sh

echo "Uninstall riff system"

source $fats_dir/macros/cleanup-user-resources.sh

helm delete --purge riff
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=riff

helm delete --purge istio
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=istio
kubectl delete namespace istio-system

helm delete --purge cert-manager
kubectl delete customresourcedefinitions.apiextensions.k8s.io -l app.kubernetes.io/managed-by=Tiller,app.kubernetes.io/instance=cert-manager

source $fats_dir/macros/helm-reset.sh

kubectl delete namespace $NAMESPACE

source ${fats_dir}/cleanup.sh
