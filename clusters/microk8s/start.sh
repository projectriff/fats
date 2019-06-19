#!/bin/bash

sudo chown 0:0 /

echo "install microk8s"
sudo snap install microk8s --classic --channel=1.14/stable
microk8s.status --wait-ready

echo "enable dns"
microk8s.enable dns
sleep 2
microk8s.status --wait-ready

echo "enable storage"
microk8s.enable storage
sleep 2
microk8s.status --wait-ready

echo "expose kube config"
microk8s.kubectl config view --raw > $HOME/.kube/config
