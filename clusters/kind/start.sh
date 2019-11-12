#!/bin/bash

CLUSTER_NAME=${CLUSTER_NAME-fats}
kind create cluster --name ${CLUSTER_NAME} --wait 5m

if grep -q docker /proc/1/cgroup; then
    # running in a container
    flags=--internal
fi

# move kubeconfig to expected location
cp <(kind get kubeconfig --name ${CLUSTER_NAME} $flags) ~/.kube/config
