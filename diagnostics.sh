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

echo "##[group]riff Build logs"
kubectl logs -n riff-system -l component=build.projectriff.io,control-plane=controller-manager -c manager --tail 10000
echo "##[endgroup]"

echo "##[group]riff Core Runtime logs"
kubectl logs -n riff-system -l component=core.projectriff.io,control-plane=controller-manager -c manager --tail 10000
echo "##[endgroup]"

echo "##[group]riff Knative Runtime logs"
kubectl logs -n riff-system -l component=knative.projectriff.io,control-plane=controller-manager -c manager --tail 10000
echo "##[endgroup]"

echo "##[group]riff Streaming Runtime logs"
kubectl logs -n riff-system -l component=streaming.projectriff.io,control-plane=controller-manager -c manager --tail 10000
echo "##[endgroup]"

echo "##[group]kpack logs"
kubectl logs -n kpack -l app=kpack-controller --tail 10000
echo "##[endgroup]"

echo "##[group]Knative Serving logs"
kubectl logs -n knative-serving -l app=controller --tail 10000
echo "##[endgroup]"
