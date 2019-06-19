#!/bin/bash

sudo chown 0:0 /

echo "install microk8s"
sudo snap install microk8s --classic --channel=1.14/stable
echo "wait for microk8s"
microk8s.status --wait-ready
echo "enable dns storage"
microk8s.enable dns storage
sleep 2
echo "wait for microk8s"
microk8s.status --wait-ready

echo "expose kube config"
microk8s.kubectl config view --raw > $HOME/.kube/config
