#!/bin/bash

kind create cluster --name fats --wait 5m

if grep -q docker /proc/1/cgroup; then
    # running in a container
    flags=--internal
fi

# move kubeconfig to expected location
cp <(kind get kubeconfig --name fats $flags) ~/.kube/config
