#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

kube_ready() {
  resource=$1
  namespace=$2
  label=$3
  jsonpath=$4
  pattern=$5

  kubectl get $resource --namespace $namespace -l $label \
    -o jsonpath="$jsonpath" 2>&1 | grep -qE $pattern
}
