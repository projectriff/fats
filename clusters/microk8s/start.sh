#!/bin/bash

sudo apt update
sudo apt install snapd

echo "install microk8s"
sudo snap install microk8s --classic --channel=1.14/stable
echo "wait for microk8s"
microk8s.status --wait-ready
echo "enable dns storage"
microk8s.enable dns storage
sleep 2
echo "wait for microk8s"
microk8s.status --wait-ready

echo "alias kubectl docker"
sudo snap alias microk8s.kubectl kubectl
sudo snap alias microk8s.docker docker

echo "expose kube config"
microk8s.kubectl config view --raw > $HOME/.kube/config
