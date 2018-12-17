#!/bin/bash

echo "install microk8s"
sudo snap install microk8s --channel=1.13/stable --classic
echo "wait for microk8s"
microk8s.status --wait-ready
echo "enable dns"
microk8s.enable dns
sleep 2
echo "wait for microk8s"
microk8s.status --wait-ready

echo "alias kubectl docker"
sudo snap alias microk8s.kubectl kubectl
sudo snap alias microk8s.docker docker

echo "expose kube config"
microk8s.kubectl config view --raw > $HOME/.kube/config
