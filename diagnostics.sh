#!/bin/bash

echo "##[group]K8s resources"
kubectl get deployments,services,pods --all-namespaces
echo "##[endgroup]"

echo "##[group]riff resources"
kubectl get riff --all-namespaces
echo "##[endgroup]"

echo "##[group]kpack resources"
kubectl get clusterbuilders.build.pivotal.io,builders.build.pivotal.io,images.build.pivotal.io,sourceresolvers.build.pivotal.io,builds.build.pivotal.io --all-namespaces
echo "##[endgroup]"

echo "##[group]knative resources"
kubectl get knative --all-namespaces
echo "##[endgroup]"

echo "##[group]failing pods"
kubectl get pods --all-namespaces --field-selector=status.phase!=Running \
  | tail -n +2 | awk '{print "-n", $1, $2}' | xargs -L 1 kubectl describe pod
echo "##[endgroup]"

echo "##[group]describe nodes"
kubectl describe node
echo "##[endgroup]"

echo "##[group]describe riff"
kubectl describe riff --all-namespaces
echo "##[endgroup]"

echo "##[group]describe knative"
kubectl describe knative --all-namespaces
echo "##[endgroup]"
