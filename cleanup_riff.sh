#!/bin/bash

source ./util.sh

riff system uninstall --istio --force
kubectl delete namespace $NAMESPACE
