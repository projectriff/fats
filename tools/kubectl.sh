#!/bin/bash

kubectl_version="v1.12.3"

if [ "$machine" == "MinGw" ]; then
  curl -Lo kubectl.exe https://storage.googleapis.com/kubernetes-release/release/${kubectl_version}/bin/windows/amd64/kubectl.exe
  mv kubectl.exe /usr/bin/
else
  curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/${kubectl_version}/bin/linux/amd64/kubectl
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

unset kubectl_version
