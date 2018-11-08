#!/bin/bash

source `dirname "${BASH_SOURCE[0]}"`/util.sh

riff system uninstall --istio --force
kubectl delete namespace $NAMESPACE
