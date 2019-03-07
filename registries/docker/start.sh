#!/bin/bash

# Enable local registry
echo "Installing a local registry"
docker run --detach --publish 5000:5000 --rm --name registry registry:2

registry_ip=$(kubectl get node -o jsonpath="{.items[0].status.addresses[?(@.type=='InternalIP')].address}")
echo "Using IP $registry_ip"

# because we are running with --vm-driver=none the local host is minikube's host
sudo su -c "echo \"\" >> /etc/hosts"
sudo su -c "echo \"$registry_ip       registry.local\" >> /etc/hosts"
