#!/bin/bash

echo "unalias kubectl docker"
sudo snap unalias kubectl
sudo snap unalias docker

echo "reset microk8s"
microk8s.reset
echo "remove mocrok8s"
sudo snap remove microk8s
