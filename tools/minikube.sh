#!/bin/bash

minikube_version="${1:-v1.3.0}"
base_url="${2:-https://storage.googleapis.com/minikube/releases}"

if [ "$machine" == "MinGw" ]; then
  curl -Lo minikube.exe ${base_url}/${minikube_version}/minikube-windows-amd64.exe
  mv minikube.exe /usr/bin
else
  curl -Lo minikube ${base_url}/${minikube_version}/minikube-linux-amd64
  chmod +x minikube
  sudo mv minikube /usr/local/bin/

  sudo apt-get install socat
fi
