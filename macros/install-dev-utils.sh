#!/bin/bash

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: dev-utils
  namespace: ${NAMESPACE}
spec:
  containers:
  - name: dev-utils
    image: projectriff/dev-utils
EOF

kubectl create rolebinding --namespace $NAMESPACE dev-utils --clusterrole=view --serviceaccount=${NAMESPACE}:default
