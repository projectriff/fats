#!/bin/bash

echo "unalias kubectl docker"
snap unalias kubectl
snap unalias docker

echo "reset microk8s"
microk8s.reset
echo "remove mocrok8s"
snap remove microk8s
