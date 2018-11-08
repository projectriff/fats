#!/bin/bash

dir=`dirname "${BASH_SOURCE[0]}"`

source $dir/util.sh

riff system uninstall --istio --force
kubectl delete namespace $NAMESPACE
