#!/bin/bash

minikube_version="${1:-v1.1.0}"

echo "minikube version: ${minikube_version}"

if [ "$machine" == "MinGw" ]; then
  curl -Lo minikube.exe https://storage.googleapis.com/minikube/releases/$minikube_version/minikube-windows-amd64.exe
  mv minikube.exe /usr/bin
else
  echo "minikube url: https://storage.googleapis.com/minikube/releases/$minikube_version/minikube-linux-amd64"
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/$minikube_version/minikube-linux-amd64
  chmod +x minikube
  sudo mv minikube /usr/local/bin/
fi
