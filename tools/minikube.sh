#!/bin/bash

minikube_version="${minikube_version:-v0.30.0}"

curl -Lo minikube https://storage.googleapis.com/minikube/releases/$minikube_version/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

# Make root mounted as rshared to fix kube-dns issues.
sudo mount --make-rshared /
