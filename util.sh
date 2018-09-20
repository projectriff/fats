#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

RED='\033[0;31m'
NC='\033[0m' # No Color

kube_ready() {
  resource=$1
  namespace=$2
  jsonpath=$4
  pattern=$5

if [[ $3 = *"="* ]]; then
  label=$3

  kubectl get $resource --namespace $namespace -l $label \
    -o jsonpath="$jsonpath" 2>&1 | grep -qE $pattern
else
  name=$3

  kubectl get $resource --namespace $namespace $name \
    -o jsonpath="$jsonpath" 2>&1 | grep -qE $pattern
fi

}
