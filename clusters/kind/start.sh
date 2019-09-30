#!/bin/bash

kind create cluster --wait 5m

# move kubeconfig to expected location
cp $(kind get kubeconfig-path) ~/.kube/config
