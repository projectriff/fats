#!/bin/bash

echo "enable registry"
microk8s.enable registry
echo "wait for microk8s"
microk8s.status --wait-ready
