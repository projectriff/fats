#!/bin/bash

if [ "$machine" == "MinGw"]; then
  curl -Lo kubectl.exe https://storage.googleapis.com/kubernetes-release/release/v1.12.3/bin/windows/amd64/kubectl.exe
  mv kubectl.exe ~/bin/
else
  curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.12.3/bin/linux/amd64/kubectl
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi
