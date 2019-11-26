#!/bin/bash

# TODO pin to an appropriate tag
utils_version=latest

kubectl create serviceaccount dev-utils --namespace $NAMESPACE
kubectl create rolebinding dev-utils --namespace $NAMESPACE --clusterrole=view --serviceaccount=${NAMESPACE}:dev-utils

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: dev-utils
  namespace: ${NAMESPACE}
spec:
  serviceAccountName: dev-utils
  containers:
  - name: dev-utils
    image: projectriff/dev-utils:${utils_version}
EOF
