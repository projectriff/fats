#!/bin/bash

# Enable local registry
echo "Installing the minikube registry"
wait_pod_selector_ready kubernetes.io/minikube-addons=addon-manager kube-system
sudo minikube addons enable registry
wait_pod_selector_ready kubernetes.io/minikube-addons=registry kube-system
registry_ip=$(kubectl get svc --namespace kube-system -l "kubernetes.io/minikube-addons=registry" -o jsonpath="{.items[0].spec.clusterIP}")
# because we are running with --vm-driver=none the local host is minikube's host
sudo su -c "echo \"\" >> /etc/hosts"
sudo su -c "echo \"$registry_ip       registry.kube-system.svc.cluster.local\" >> /etc/hosts"
