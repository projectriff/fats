#!/bin/bash

# TODO pin to an appropriate tag
utils_version=latest

kubectl create serviceaccount riff-dev --namespace $NAMESPACE
kubectl create rolebinding riff-dev --namespace $NAMESPACE --clusterrole=view --serviceaccount=${NAMESPACE}:riff-dev

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: riff-dev
  namespace: ${NAMESPACE}
spec:
  serviceAccountName: riff-dev
  containers:
  - name: utils
    image: projectriff/dev-utils:${utils_version}
EOF
kubectl wait pods --for=condition=Ready riff-dev --namespace $NAMESPACE --timeout=60s

