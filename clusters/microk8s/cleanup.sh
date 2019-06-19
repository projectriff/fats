#!/bin/bash

echo "reset microk8s"
microk8s.reset
echo "remove mocrok8s"
sudo snap remove microk8s
