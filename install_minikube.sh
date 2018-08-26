#!/bin/bash

source ./util.sh

export CHANGE_MINIKUBE_NONE_USER=true

# install minikube if needed
if hash minikube 2>/dev/null; then
  echo "Skipping minikube install"
else
  echo "Installing minikube"
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
    chmod +x minikube && sudo mv minikube /usr/local/bin/
fi

# TODO make vm driver configurable
minikube start --memory=8192 --cpus=4 \
  --kubernetes-version=v1.10.5 \
  --vm-driver=none \
  --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
  --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" \
  --extra-config=apiserver.admission-control="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"

echo "Create auth secret"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: push-credentials
  annotations:
    build.knative.dev/docker-0: https://index.docker.io/v1/
type: kubernetes.io/basic-auth
data:
  username: $(echo -n "$DOCKER_USERNAME" | openssl base64 -a -A)
  password: $(echo -n "$DOCKER_PASSWORD" | openssl base64 -a -A)
EOF
