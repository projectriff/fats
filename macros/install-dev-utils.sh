#!/bin/bash

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: dev-utils
spec:
  containers:
  - name: dev-utils
    image: projectriff/dev-utils
EOF

kubectl create clusterrolebinding dev-util-stream --clusterrole=riff-streaming-readonly-role --serviceaccount=default:default
kubectl create clusterrolebinding dev-util-core --clusterrole=riff-core-readonly-role --serviceaccount=default:default
kubectl create clusterrolebinding dev-util-knative --clusterrole=riff-knative-readonly-role --serviceaccount=default:default
