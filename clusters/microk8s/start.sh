#!/bin/bash

echo "install microk8s"
sudo snap install microk8s --channel=1.12/stable --classic
echo "wait for microk8s"
microk8s.status --wait-ready

echo "alias kubectl docker"
snap alias microk8s.kubectl kubectl
snap alias microk8s.docker docker
